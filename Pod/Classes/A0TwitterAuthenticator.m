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

#import <Lock/A0AuthParameters.h>
#import <Lock/NSObject+A0APIClientProvider.h>
#import <Lock/A0APIClient.h>
#import <Lock/A0Errors.h>
#import <Lock/A0Strategy.h>
#import <Lock/A0IdentityProviderCredentials.h>
#import "A0Twitter.h"

@interface A0TwitterAuthenticator ()
@property (readonly, nonatomic) NSString *connectionName;
@property (readonly, nonatomic) A0Twitter *twitter;
@end

@implementation A0TwitterAuthenticator

- (instancetype)initWithConnectionName:(NSString *)connectionName consumerKey:(NSString *)consumerKey {
    self = [super init];
    if (self) {
        _connectionName = [connectionName copy];
        _twitter = [[A0Twitter alloc] initWithConsumerKey:consumerKey];
    }
    return self;
}

+ (A0TwitterAuthenticator *)newAuthenticatorWithConsumerKey:(NSString *)consumerKey {
    return [[self alloc] initWithConnectionName:@"twitter" consumerKey:consumerKey];
}

#pragma mark - Reverse Auth

- (void)requestAuthSignatureWithCallback:(void(^)(NSError *, NSString *))callback {
    A0APIClient *client = [self a0_apiClientFromProvider:self.clientProvider];
    NSURL *baseUrl = client.baseURL;
    NSString *clientId = client.clientId;
    NSURL *url = [NSURL URLWithString:@"/oauth/reverse" relativeToURL:baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    NSDictionary<NSString *, id> *body = @{
                                           @"connection": self.connectionName,
                                           @"client_id": clientId,
                                           };
    NSError *serializationError;
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:&serializationError];
    if (serializationError) {
        callback(serializationError, nil);
        return;
    }
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                        if (error) {
                                            callback(error, nil);
                                            return;
                                        }
                                        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
                                        if ((http.statusCode > 299 || http.statusCode < 200) || !data) {
                                            callback([A0Errors twitterNotConfigured], nil);
                                            return;
                                        }
                                        NSError *deserializationError;
                                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializationError];
                                        if (deserializationError) {
                                            callback(deserializationError, nil);
                                            return;
                                        }
                                        NSString *signature = json[@"result"];
                                        NSError *resultError = signature ? nil : [A0Errors twitterNotConfigured];
                                        callback(resultError, signature);
                                    }] resume];
}

#pragma mark - A0AuthenticationProvider

- (void)authenticateWithParameters:(A0AuthParameters *)parameters success:(A0IdPAuthenticationBlock)success failure:(A0IdPAuthenticationErrorBlock)failure {
    __weak __typeof__(self) weakSelf = self;
    void(^onAuth)(NSError *error, A0UserProfile *profile, A0Token *token) = ^(NSError *error, A0UserProfile *profile, A0Token *token) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                return failure(error);
            }
            success(profile, token);
        });
    };

    void(^onReverseAuth)(NSError *, NSString *, NSString *, NSString *) = ^(NSError *error, NSString *token, NSString *secret, NSString *userId) {
        NSDictionary *extraInfo = @{
                                    A0StrategySocialTokenParameter: token,
                                    A0StrategySocialTokenSecretParameter: secret,
                                    A0StrategySocialUserIdParameter: userId,
                                    };
        A0IdentityProviderCredentials *credentials = [[A0IdentityProviderCredentials alloc] initWithAccessToken:token extraInfo:extraInfo];
        A0APIClient *client = [weakSelf a0_apiClientFromProvider:weakSelf.clientProvider];
        [client authenticateWithSocialConnectionName:weakSelf.connectionName
                                         credentials:credentials
                                          parameters:parameters
                                             success:^(A0UserProfile *profile, A0Token *token) {
                                                 onAuth(nil, profile, token);
                                             }
                                             failure:^(NSError *error) {
                                                 onAuth(error, nil, nil);
                                             }];
    };

    void(^onReverseAuthSignature)(NSError *error, ACAccount *account, NSString *signature) = ^(NSError *error, ACAccount *account, NSString *signature) {
        if (error) {
            return onAuth(error, nil, nil);
        }
        [weakSelf.twitter completeReverseAuthWithAccount:account
                                               signature:signature
                                                callback:onReverseAuth];
    };

    void(^onAccountSelected)(NSError *error, ACAccount *account) = ^(NSError *error, ACAccount *account) {
        if (error) {
            return onAuth(error, nil, nil);
        }
        [weakSelf requestAuthSignatureWithCallback:^(NSError *error, NSString *signature) {
            onReverseAuthSignature(error, account, signature);
        }];
    };

    [self.twitter chooseAccountWithCallback:onAccountSelected];
}

- (NSString *)identifier {
    return self.connectionName;
}

- (void)clearSessions {
    
}
@end
