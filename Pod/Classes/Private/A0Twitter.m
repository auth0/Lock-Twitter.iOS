// A0Twitter.m
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
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

#import "A0Twitter.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import <Lock/A0Errors.h>
#import "NSURLResponse+A0HTTPResponse.h"
#import "Utilities.h"

@interface A0Twitter ()
@property (readonly, nonatomic) NSString *consumerKey;
@property (strong, nonatomic) ACAccountStore *store;
@property (strong, nonatomic) ACAccountType *type;
@end

@implementation A0Twitter

- (instancetype)initWithConsumerKey:(NSString *)consumerKey {
    self = [super init];
    if (self) {
        _consumerKey = [consumerKey copy];
        _store = [[ACAccountStore alloc] init];
        _type = [_store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    }
    return self;
}

+ (BOOL)isAvailable {
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

- (void)chooseAccountFromController:(UIViewController *)controller callback:(onAccoutSelected)callback {
    [self.store requestAccessToAccountsWithType:self.type options:nil completion:^(BOOL granted, NSError *error) {
        if (error || !granted) {
            return callback([A0Errors twitterAppNotAuthorized], nil);
        }
        NSArray *accounts = [self.store accountsWithAccountType:self.type];

        if (accounts.count == 1) {
            return callback(nil, accounts.firstObject);
        }

        UIAlertController *sheet;

        if (accounts.count > 0) {
            NSString *title = A0LocalizedString(@"com.auth0.lock.integration.twitter.choose-account.title", @"Please choose a twitter account", @"Account chooser title");
            sheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [accounts enumerateObjectsUsingBlock:^(ACAccount  * _Nonnull account, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *title = [@"@" stringByAppendingString:account.username];
                UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   callback(nil, account);
                                                               }];
                [sheet addAction:action];
            }];
        } else {
            NSString *title = A0LocalizedString(@"com.auth0.lock.integration.twitter.choose-account.no-account.title", @"There was no twitter account configured in your iOS device", @"No account title");
            NSString *message = A0LocalizedString(@"com.auth0.lock.integration.twitter.choose-account.no-account.message", @"Please go to iOS Settings > Twitter, add your account and try again.", @"No account registered in iOS");
            sheet = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
        }

        NSString *cancelTitle = A0LocalizedString(@"com.auth0.lock.integration.twitter.choose-account.cancel", @"Cancel", @"Cancel button");
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 callback([A0Errors twitterCancelled], nil);
                                                             }];
        [sheet addAction:cancelAction];

        [controller presentViewController:sheet animated:YES completion:nil];
    }];
}

- (void)completeReverseAuthWithAccount:(ACAccount *)account signature:(NSString *)signature callback:(onReverseAuth)callback {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:@{
                                                            @"x_reverse_auth_target": self.consumerKey,
                                                            @"x_reverse_auth_parameters": signature,
                                                            }];
    [request setAccount:account];
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error || !responseData) {
            return callback(error, nil, nil, nil);
        }
        if (![urlResponse a0_isSuccess]) {
            return callback([A0Errors twitterAppOauthNotAuthorized], nil, nil, nil);
        }
        NSError *failureError;
        NSDictionary *payload = [A0Twitter payloadFromResponseData:responseData error:&failureError];
        callback(failureError, payload[@"oauth_token"], payload[@"oauth_token_secret"], payload[@"user_id"]);
    }];
}

+ (NSDictionary *)payloadFromResponseData:(NSData *)responseData error:(NSError **)error {
    NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    BOOL failed = responseStr && [responseStr rangeOfString:@"<error code=\""].location != NSNotFound;
    if (failed) {
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
                *error = [A0Errors twitterNotConfigured];
            }
            if (error89) {
                *error = [A0Errors twitterInvalidAccount];
            }
        }
        return nil;
    }
    NSURL *responseURL = [NSURL URLWithString:[@"https://auth0.com/callback?" stringByAppendingString:responseStr]];
    NSURLComponents *components = [NSURLComponents componentsWithURL:responseURL resolvingAgainstBaseURL:YES];
    NSMutableDictionary *payload = [@{} mutableCopy];
    [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        if (item.value) {
            payload[item.name] = item.value;
        }
    }];
    if (payload[@"oauth_token"] && payload[@"oauth_token_secret"] && payload[@"user_id"]) {
        return payload;
    } else {
        *error = [A0Errors twitterAppNotAuthorized];
        return nil;
    }
}

@end
