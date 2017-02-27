// TwitterNativeTransaction.swift
//
// Copyright (c) 2017 Auth0 (http://auth0.com)
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

import Foundation
import Auth0
import Social

class TwitterNativeTransaction: NativeAuthTransaction {

    var connection: String
    var scope: String
    var parameters: [String : Any]
    var authentication: Authentication
    var consumerKey: String

    public init(connection: String, scope: String, parameters: [String: Any], authentication: Authentication, consumerKey: String) {
        self.connection = connection
        self.scope = scope
        self.parameters = parameters
        self.authentication = authentication
        self.consumerKey = consumerKey
    }

    var delayed: NativeAuthTransaction.Callback = { _ in }

    func auth(callback: @escaping NativeAuthTransaction.Callback) {

        let twitter = Twitter()
        twitter.retrieveAccount() { error, account in
            guard error == nil, let account = account else { return self.delayed(.failure(error: error!)) }

            twitter.retrieveSignature(forAccount: account) { error, signature in
                guard error == nil, let signature = signature else { return self.delayed(.failure(error: error!)) }

                twitter.retrieveToken(withSignature: signature, account: account, consumerKey: self.consumerKey) { error, token in

                    guard error == nil, let token = token else { return self.delayed(.failure(error: error!)) }

                    guard let accessToken = token["oauth_token"],
                        let tokenSecret = token["oauth_token_secret"],
                        let userId = token["user_id"]
                        else { return self.delayed(.failure(error: TwitterError.missingToken)) }

                    var extras: [String: Any] = [:]
                    extras["access_token_secret"] = tokenSecret
                    extras["user_id"] = userId
                    self.delayed(.success(result: NativeAuthCredentials(token: accessToken, extras: extras)))
                }
            }

        }
        self.delayed = callback

    }

    func cancel() {
        self.delayed(.failure(error: WebAuthError.userCancelled))
        self.delayed = { _ in }
    }

    public func resume(_ url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return true
    }
}
