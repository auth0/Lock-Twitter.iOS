// A0TwitterAuthenticator.m
//
// Copyright (c) 2014 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "A0TwitterAuthenticator.h"

#import <Lock/A0Errors.h>
#import <Lock/A0Strategy.h>
#import <Lock/A0APIClient.h>
#import <Lock/A0Application.h>
#import <Lock/A0IdentityProviderCredentials.h>
#import <Lock/NSObject+A0APIClientProvider.h>
#import <Lock/A0Logging.h>

#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import <TWReverseAuth/TWAPIManager.h>
#import <OAuthCore/OAuth+Additions.h>
#import <PSAlertView/PSPDFActionSheet.h>
#import "BDBOAuth1SessionManager.h"

#define kCallbackURLString @"a0%@://%@.auth0.com/authorize"

@interface A0TwitterAuthenticator ()

@property (strong, nonatomic) A0AuthParameters *parameters;
@property (strong, nonatomic) BDBOAuth1SessionManager *manager;
@property (strong, nonatomic) NSURL *callbackURL;
@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccountType *accountType;
@property (assign, atomic) BOOL authenticating;

@property (copy, nonatomic) void(^successBlock)(A0UserProfile *profile, A0Token *token);
@property (copy, nonatomic) void(^failureBlock)(NSError *);

@end

@implementation A0TwitterAuthenticator

+ (A0TwitterAuthenticator *)newAuthenticatorWithKey:(NSString *)key andSecret:(NSString *)secret {
    return [[A0TwitterAuthenticator alloc] initWithKey:key andSecret:secret];
}

- (instancetype)initWithKey:(NSString *)key andSecret:(NSString *)secret {
    self = [super init];
    if (self) {
        _authenticating = NO;
        _manager = [[BDBOAuth1SessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/"]
                                                                 consumerKey:key
                                                              consumerSecret:secret];
        [_manager deauthorize];
        [TWAPIManager registerTwitterAppKey:key andAppSecret:secret];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationActiveNotification:(NSNotification *)notification {
    if (!self.authenticating) {
        if (self.failureBlock) {
            self.failureBlock([A0Errors twitterCancelled]);
        }
        self.successBlock = nil;
        self.failureBlock = nil;
    }
}

#pragma mark - A0SocialProviderAuth

- (NSString *)identifier {
    return A0StrategyNameTwitter;
}

- (void)clearSessions {
    self.successBlock = nil;
    self.failureBlock = nil;
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    BOOL handled = NO;
    A0LogVerbose(@"Received url %@ from source application %@", url, sourceApplication);
    if ([url.scheme.lowercaseString isEqualToString:self.callbackURL.scheme.lowercaseString] && [url.host isEqualToString:self.callbackURL.host]) {
        handled = YES;
        self.authenticating = YES;
        NSDictionary *parameters = [NSURL ab_parseURLQueryString:url.query];
        if (parameters[@"oauth_token"] && parameters[@"oauth_verifier"]) {
            A0LogVerbose(@"Requesting access token from twitter...");
            [self.manager fetchAccessTokenWithPath:@"/oauth/access_token"
                                            method:@"POST"
                                      requestToken:[BDBOAuth1Credential credentialWithQueryString:url.query]
                                           success:^(BDBOAuth1Credential *accessToken) {
                A0LogDebug(@"Received token %@ with userInfo %@", accessToken.token, accessToken.userInfo);
                [self reverseAuthWithNewAccountWithInfo:accessToken];
            } failure:^(NSError *error) {
                A0LogError(@"Failed to request access token with error %@", error);
                [self executeFailureWithError:error];
            }];
        } else {
            A0LogError(@"Twitter OAuth 1.1 flow was cancelled by the user");
            [self executeFailureWithError:[A0Errors twitterCancelled]];
        }
    }
    return handled;
}

- (void)authenticateWithParameters:(A0AuthParameters *)parameters success:(void (^)(A0UserProfile *, A0Token *))success failure:(void (^)(NSError *))failure {
    self.successBlock = success;
    self.failureBlock = failure;
    self.accountStore = [[ACAccountStore alloc] init];
    self.accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    self.parameters = parameters;
    A0LogVerbose(@"Starting Twitter authentication...");

    NSString *clientId = [[self a0_apiClientFromProvider:self.clientProvider] clientId];
    NSString *callbackURLString = [NSString stringWithFormat:kCallbackURLString, clientId, @"twitter"].lowercaseString;
    self.callbackURL = [NSURL URLWithString:callbackURLString];

    A0LogVerbose(@"Registering callback URL %@", self.callbackURL);

    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        A0LogVerbose(@"Requesting access to iOS Twitter integration for Accounts");
        [self.accountStore requestAccessToAccountsWithType:self.accountType options:nil completion:^(BOOL granted, NSError *error) {
            if (granted && !error) {
                NSArray *accounts = [self.accountStore accountsWithAccountType:self.accountType];
                A0LogDebug(@"Obtained %lu accounts from iOS Twitter integration", (unsigned long)accounts.count);
                if (accounts.count > 1) {
                    A0LogVerbose(@"Asking the user to choose one account from the list...");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        PSPDFActionSheet *sheet = [[PSPDFActionSheet alloc] initWithTitle:nil];
                        for (ACAccount *account in accounts) {
                            [sheet addButtonWithTitle:[@"@" stringByAppendingString:account.username] block:^(NSInteger buttonIndex) {
                                A0LogDebug(@"User picked account with screen name @%@", account.username);
                                [self reverseAuthForAccount:account];
                            }];
                        }
                        [sheet setCancelButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"Lock", nil) block:^(NSInteger buttonIndex) {
                            A0LogDebug(@"User did not pick an account");
                            [self executeFailureWithError:[A0Errors twitterCancelled]];
                        }];
                        [sheet showInView:[[UIApplication sharedApplication] keyWindow]];
                    });
                } else {
                    A0LogVerbose(@"Only one account found, no need for the user to pick one");
                    [self reverseAuthForAccount:accounts.firstObject];
                }
            } else {
                A0LogError(@"Failed to obtain accounts from iOS Twitter integration with error %@", error);
                [self executeFailureWithError:[A0Errors twitterAppNotAuthorized]];
            }
        }];
    } else {
        A0LogVerbose(@"No account was found in iOS Twitter integration. Starting with OAuth web flow...");
        [self.manager deauthorize];
        [self.manager fetchRequestTokenWithPath:@"/oauth/request_token"
                                         method:@"POST"
                                    callbackURL:self.callbackURL
                                          scope:nil
                                        success:^(BDBOAuth1Credential *requestToken) {
            A0LogDebug(@"Obtained request token %@ with user info %@", requestToken.token, requestToken.userInfo);
            NSString *authURL = [NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@", requestToken.token];
            A0LogVerbose(@"Opening in Safari URL: %@", authURL);
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:authURL]];
        } failure:^(NSError *error) {
            A0LogError(@"Failed to obtain request token with error %@", error);
            [self executeFailureWithError:error];
        }];
    }
}

#pragma mark - Twitter Reverse Auth
- (void)reverseAuthWithNewAccountWithInfo:(BDBOAuth1Credential *)info {
    ACAccountCredential * credential = [[ACAccountCredential alloc] initWithOAuthToken:info.token tokenSecret:info.secret];
    ACAccount * account = [[ACAccount alloc] initWithAccountType:self.accountType];
    account.accountType = self.accountType;
    account.credential = credential;
    account.username = [NSString stringWithFormat:@"@%@", info.userInfo[@"screen_name"]];

    A0LogDebug(@"About to save Twitter account @%@ in iOS Twitter integration.", account.username);
    [self.accountStore requestAccessToAccountsWithType:self.accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted) {
            A0LogVerbose(@"Saving new twitter account in iOS...");
            [self.accountStore saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
                if (success && !error) {
                    ACAccount *account = [[self.accountStore accountsWithAccountType:self.accountType] firstObject];
                    A0LogDebug(@"Saved twitter account @%@", account.username);
                    [self reverseAuthForAccount:account];
                } else {
                    A0LogError(@"Failed to save twitter account with error %@", error);
                    [self executeFailureWithError:error];
                }
            }];
        }
        else {
            A0LogError(@"Failed to access iOS Twitter integration with error %@", error);
            [self executeFailureWithError:[A0Errors twitterAppNotAuthorized]];
        }
    }];
}

- (void)reverseAuthForAccount:(ACAccount *)account {
    account.accountType = self.accountType;
    A0LogVerbose(@"Starting reverse authentication with Twitter account @%@...", account.username);

    __weak A0TwitterAuthenticator *weakSelf = self;
    [TWAPIManager performReverseAuthForAccount:account withHandler:^(NSData *responseData, NSError *error) {
        if (error || !responseData) {
            A0LogError(@"Failed to perform reverse auth with error %@", error);
            [weakSelf executeFailureWithError:error];
        } else {
            NSError *payloadError;
            NSDictionary *response = [A0TwitterAuthenticator payloadFromResponseData:responseData error:&payloadError];
            if (!payloadError) {
                A0LogDebug(@"Reverse Auth successful. Received payload %@", response);
                NSString *oauthToken = response[@"oauth_token"];
                NSString *oauthTokenSecret = response[@"oauth_token_secret"];
                NSString *userId = response[@"user_id"];
                NSDictionary *extraInfo = @{
                                            A0StrategySocialTokenParameter: oauthToken,
                                            A0StrategySocialTokenSecretParameter: oauthTokenSecret,
                                            A0StrategySocialUserIdParameter: userId,
                                            };
                A0IdentityProviderCredentials *credentials = [[A0IdentityProviderCredentials alloc] initWithAccessToken:response[@"oauth_token"] extraInfo:extraInfo];
                A0LogDebug(@"Successful Twitter auth with credentials %@", credentials);
                [weakSelf executeSuccessWithCredentials:credentials parameters:weakSelf.parameters];
            } else {
                [weakSelf executeFailureWithError:payloadError];
            }
        }
    }];
}

+ (NSDictionary *)payloadFromResponseData:(NSData *)responseData error:(NSError **)error {
    NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    BOOL failed = responseStr && [responseStr rangeOfString:@"<error code=\""].location != NSNotFound;
    NSDictionary *payload;
    if (failed) {
        A0LogError(@"Failed reverse auth with payload %@", responseStr);
        // <?xml version="1.0" encoding="UTF-8"?>
        // <errors>
        //   <error code="87">Client is not permitted to perform this action</error>
        // </errors>
        BOOL error87 = responseStr && [responseStr rangeOfString:@"<error code=\"87\">"].location != NSNotFound;
        // <?xml version="1.0" encoding="UTF-8"?>
        // <errors>
        //   <error code="89">Error processing your OAuth request: invalid signature or token</error>
        // </errors>
        BOOL error89 = responseStr && [responseStr rangeOfString:@"<error code=\"89\">"].location != NSNotFound;
        if (error != NULL) {
            *error = [A0Errors twitterAppNotAuthorized];
            if (error87) {
                A0LogError(@"Twitter app not configured in Auth0");
                *error = [A0Errors twitterNotConfigured];
            }
            if (error89) {
                A0LogError(@"Twitter Account in iOS is invalid. Re-enter credentials in Settings > Twitter");
                *error = [A0Errors twitterInvalidAccount];
            }
        }

    } else {
        payload = [NSURL ab_parseURLQueryString:responseStr];
        NSString *oauthToken = payload[@"oauth_token"];
        NSString *oauthTokenSecret = payload[@"oauth_token_secret"];
        NSString *userId = payload[@"user_id"];
        if (!(oauthToken || oauthTokenSecret || userId)) {
            A0LogError(@"Reverse auth didnt return all credential info (token, token_secret & user_id)");
            if (error != NULL) {
                *error = [A0Errors twitterAppNotAuthorized];
            }
        }
    }
    return payload;
}

#pragma mark - Block handling

- (void)executeSuccessWithCredentials:(A0IdentityProviderCredentials *)credentials parameters:(A0AuthParameters *)parameters {
    A0APIClient *client = [self a0_apiClientFromProvider:self.clientProvider];
    [client authenticateWithSocialConnectionName:self.identifier
                                     credentials:credentials
                                      parameters:parameters
                                         success:self.successBlock
                                         failure:self.failureBlock];
    self.authenticating = NO;
    self.successBlock = nil;
    self.failureBlock = nil;
    self.accountStore = nil;
    self.accountType = nil;
}

- (void)executeFailureWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.failureBlock) {
            self.failureBlock(error);
        }
        self.authenticating = NO;
        self.successBlock = nil;
        self.failureBlock = nil;
        self.accountStore = nil;
        self.accountType = nil;
    });
}
@end
