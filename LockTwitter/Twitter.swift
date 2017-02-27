// TwitterHelper.swift
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
import Accounts
import Social

public struct Twitter {

    func retrieveAccount(callback: @escaping (TwitterError?, ACAccount?) -> ()) {
        let account = ACAccountStore()
        let accountType = account.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)

        account.requestAccessToAccounts(with: accountType, options: nil) { (success, error) in
            guard error == nil else { return callback(.accountAccessDenied, nil) }

            guard let accounts = account.accounts(with: accountType) else { return callback(.noValidAccounts, nil) }

            if accounts.count == 1, let twitterAccount = accounts.first as? ACAccount {
                return callback(nil, twitterAccount)
            }

            let alert = UIAlertController(title: "Choose Account", message: nil, preferredStyle: .actionSheet)
            accounts.forEach {
                let account = $0 as? ACAccount
                let accountSelect = UIAlertAction(title: account?.username , style: .default) { action in
                    callback(nil, account)
                }
                alert.addAction(accountSelect)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
                callback(.cancelled, nil)
            }
            alert.addAction(cancel)

            if var topController = UIApplication.shared.keyWindow?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                topController.present(alert, animated: true, completion: nil)
            }
        }
    }

    func retrieveSignature(forAccount account: ACAccount, callback: @escaping (TwitterError?, String?) -> ()) {

        guard
            let url = URL(string: "https://api.twitter.com/oauth/request_token"),
            let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: url, parameters: ["x_auth_mode": "reverse_auth"])
            else { return callback(.signatureRequest, nil) }

        request.account = account
        request.perform() { data, response, error in
            guard error == nil,
                let data = data,
                let signature = String(data: data, encoding: .utf8)
                else { return callback(.signatureRequest, nil) }

            callback(nil, signature)
        }

    }

    func retrieveToken(withSignature signature: String, account: ACAccount, consumerKey: String, callback: @escaping (TwitterError?, [String: String]?) -> ()) {

        let parameters = ["x_reverse_auth_target": consumerKey,
                          "x_reverse_auth_parameters": signature]

        guard
            let url = URL(string: "https://api.twitter.com/oauth/access_token"),
            let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: url, parameters: parameters) else { return callback(.reverseAuthRequest, nil) }

        request.account = account
        request.perform() { data, response, error in
            guard error == nil,
                let data = data,
                let token = String(data: data, encoding: .utf8)?.components(separatedBy: "&")
                else { return callback(.reverseAuthRequest, nil) }

            let tokenParameters = token
                .map({ $0.components(separatedBy: "=") })
                .reduce( [String: String]()) { base, comps in
                    var dict = base
                    dict[comps[0]] = comps[1]
                    return dict
            }

            callback(nil, tokenParameters)
        }
    }
}
