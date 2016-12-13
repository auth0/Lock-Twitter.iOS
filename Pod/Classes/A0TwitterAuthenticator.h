// A0TwitterAuthenticator.h
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

#import <Foundation/Foundation.h>
#import <Lock/A0BaseAuthenticator.h>

/**
 * `A0TwitterAuthentication` handles the authentication using Twitter as an indentity provider. In order to obtain a valid token to send to Auth0 API, it uses reverse authentication with the user's login information obtained form iOS Twitter integration.
 * If there is no account registered in iOS it will fail.
 *
 * To configure it, you need to go to https://manage.auth0.com/#/connections/social, select Twitter and configure your consumer key and secret there.
 * Then use the same consumer key to create `A0TwitterAuthenticator` instance.
 */
@interface A0TwitterAuthenticator : A0BaseAuthenticator

/**
 * Creates a new twitter authenticator using a twitter api consumer key.
 * By default the connection name is twitter
 * @param consumerKey: consumer key of your twitter app
 * @return a new twitter authenticator
 */
+ (A0TwitterAuthenticator *)newAuthenticatorWithConsumerKey:(NSString *)consumerKey;

/**
 * Creates a new twitter authenticator using a twitter api consumer key and connection name.
 * @param connectionName: name of the twitter connection
 * @param consumerKey: consumer key of your twitter app
 * @return a new twitter authenticator
 */
+ (A0TwitterAuthenticator *)newAuthenticatorWithConnectionName:(NSString *)connectionName consumerKey:(NSString *)consumerKey;

/**
 * Checks if Twitter iOS integration is available and configured
 */
+ (BOOL)canUseNativeTwitterAuthentication;

@end
