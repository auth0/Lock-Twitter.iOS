# Lock-Twitter

[![CI Status](http://img.shields.io/travis/auth0/Lock-Twitter.iOS.svg?style=flat)](https://travis-ci.org/auth0/Lock-Twitter.iOS)
[![Version](https://img.shields.io/cocoapods/v/Lock-Twitter.svg?style=flat)](http://cocoapods.org/pods/Lock-Twitter)
[![License](https://img.shields.io/cocoapods/l/Lock-Twitter.svg?style=flat)](http://cocoapods.org/pods/Lock-Twitter)
[![Platform](https://img.shields.io/cocoapods/p/Lock-Twitter.svg?style=flat)](http://cocoapods.org/pods/Lock-Twitter)

[Auth0](https://auth0.com) is an authentication broker that supports social identity providers as well as enterprise identity providers such as Active Directory, LDAP, Google Apps and Salesforce.

Lock-Twitter helps you integrate native Login with Twitter and [Lock](https://auth0.com/lock)

# Deprecation notice

This package relies on a token endpoint that is now considered deprecated. **If your Auth0 client was created after Jun 8th 2017 you won't be able to use this package**. This repository is left for reference purposes.

**We recommend using browser-based flows to authenticate users**. You can do that using the [auth0.swift](https://github.com/auth0/Auth0.swift#authentication-with-hosted-login-page-ios-only) package, as explained in [this document](https://auth0.com/docs/libraries/auth0-swift).

## Usage

## Requierements

iOS 9+

## Install

The Lock-Twitter is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "Lock-Twitter", "~> 2.0"
```

## Usage

Twitter authentication use [Reverse Auth](https://dev.twitter.com/docs/ios/using-reverse-auth) to obtain a valid access_token that can be sent to Auth0 Server and validate the user.

First create a new instance of `A0TwitterAuthenticator`

```objc
NSString *twitterApiKey = ...
A0TwitterAuthenticator *twitter = [A0TwitterAuthenticator newAuthenticationWithConsumerKey:twitterApiKey];
```

```swift
let twitterApiKey = ... //Remember to obfuscate your api key
let twitter = A0TwitterAuthenticator.newAuthentication(withConsumerKey: twitterApiKey)
```

and register it with your instance of `A0Lock` if native integration is available

```objc
A0Lock *lock = ... //Get your instance of A0Lock
if ([A0TwitterAuthenticator canUseNativeTwitterAuthentication]) {
    [lock registerAuthenticators:@[twitter]];
}
```

```swift
let lock = ... //Get your instance of A0Lock
if A0TwitterAuthenticator.canUseNativeTwitterAuthentication() {
    lock.registerAuthenticators([twitter])
}
```

### Localization

For the case when there are more than one twitter account, Lock-Twitter will let the user choose one use an action sheet. Here are the keys you need to add to your `Localizable.strings` file

- **com.auth0.lock.integration.twitter.choose-account.title**: Title when choosing from multiple accounts
- **com.auth0.lock.integration.twitter.choose-account.cancel**: Cancel button title of the action sheet

Also when there are no accounts, Lock-Twitter will show an alert with an error that can be customizable with the following keys:

- **com.auth0.lock.integration.twitter.choose-account.no-account.title**: Title when no twitter account is found in the iOS device
- **com.auth0.lock.integration.twitter.choose-account.no-account.message**: Messsage when no twitter account is found in the iOS device

##API

###A0TwitterAuthenticator

####A0TwitterAuthenticator#canUseNativeTwitterAuthentication:
```objc
+ (BOOL)canUseNativeTwitterAuthentication;
```
Checks if it twitter native integration is available in the device.
```objc
BOOL canUse = [A0TwitterAuthenticator canUseNativeTwitterAuthentication];
```
```swift
let canUse = A0TwitterAuthenticator.canUseNativeTwitterAuthentication()
```

####A0TwitterAuthenticator#newAuthenticatorWithConsumerKey:
```objc
+ (A0TwitterAuthenticator *)newAuthenticatorWithConsumerKey:(NSString *)key;
```
Create a new 'A0TwitterAuthenticator' using a Twitter API key for the default twitter connection name.
```objc
A0TwitterAuthenticator *twitter = [A0TwitterAuthenticator newAuthenticatorWithConsumerKey:@"KEY"];
```
```swift
let twitter = A0TwitterAuthenticator.newAuthenticator(withConsumerKey: "KEY")
```

####A0TwitterAuthenticator#newAuthenticatorWithConnectionName:consumerKey:
```objc
+ (A0TwitterAuthenticator *)newAuthenticatorWithConnectionName:(NSString *)connectionName consumerKey:(NSString *)consumerKey;
```
Create a new 'A0TwitterAuthenticator' using a Twitter API key and a connection name.
```objc
A0TwitterAuthenticator *twitter = [A0TwitterAuthenticator newAuthenticatorWithConnectionName:@"my-twitter" consumerKey:@"KEY"];
```
```swift
let twitter = A0TwitterAuthenticator.newAuthenticator(withConnectionName: "my-twitter", consumerKey: "KEY")
```

## Issue Reporting

If you have found a bug or if you have a feature request, please report them at this repository issues section. Please do not report security vulnerabilities on the public GitHub issue tracker. The [Responsible Disclosure Program](https://auth0.com/whitehat) details the procedure for disclosing security issues.

## What is Auth0?

Auth0 helps you to:

* Add authentication with [multiple authentication sources](https://docs.auth0.com/identityproviders), either social like **Google, Facebook, Microsoft Account, LinkedIn, GitHub, Twitter, Box, Salesforce, amont others**, or enterprise identity systems like **Windows Azure AD, Google Apps, Active Directory, ADFS or any SAML Identity Provider**.
* Add authentication through more traditional **[username/password databases](https://docs.auth0.com/mysql-connection-tutorial)**.
* Add support for **[linking different user accounts](https://docs.auth0.com/link-accounts)** with the same user.
* Support for generating signed [Json Web Tokens](https://docs.auth0.com/jwt) to call your APIs and **flow the user identity** securely.
* Analytics of how, when and where users are logging in.
* Pull data from other sources and add it to the user profile, through [JavaScript rules](https://docs.auth0.com/rules).

## Create a free account in Auth0

1. Go to [Auth0](https://auth0.com) and click Sign Up.
2. Use Google, GitHub or Microsoft Account to login.

## Author

[Auth0](auth0.com)

## License

Lock-Twitter is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

