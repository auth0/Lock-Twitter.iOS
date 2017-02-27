# Lock-Twitter

[![CI Status](http://img.shields.io/travis/auth0/Lock-Twitter.iOS.svg?style=flat)](https://travis-ci.org/auth0/Lock-Twitter.iOS)
[![Version](https://img.shields.io/cocoapods/v/Lock-Twitter.svg?style=flat)](http://cocoapods.org/pods/Lock-Twitter)
[![License](https://img.shields.io/cocoapods/l/Lock-Twitter.svg?style=flat)](http://cocoapods.org/pods/Lock-Twitter)
[![Platform](https://img.shields.io/cocoapods/p/Lock-Twitter.svg?style=flat)](http://cocoapods.org/pods/Lock-Twitter)

[Auth0](https://auth0.com) is an authentication broker that supports social identity providers as well as enterprise identity providers such as Active Directory, LDAP, Google Apps and Salesforce.

Lock-Twitter helps you integrate native Login with Twitter and [Lock](https://auth0.com/lock)

## Usage

## Requirements

- iOS 9 or later
- Xcode 8
- Swift 3.0

## Install

### CocoaPods

 Add the following line to your Podfile:

 ```ruby
 pod "Lock-Facebook", "~> 3.0.0.beta"
 ```

### Carthage

In your `Cartfile` add

```
github "auth0/Lock-Twitter.iOS" "3.0.0.beta"
```

## Usage

First import **LockTwitter**

```swift
import LockFacebook
```

## Before you start using Lock-Twitter

In order to authenticate against Twitter, you'll need to register your application in [Twitter Developer portal](https://apps.twitter.com/).
You will need the Consumer Key from the app, you can follow our [Connect your client to Twitter Guide](https://auth0.com/docs/connections/social/twitter).

## Usage

Just create a new instance of `LockTwitter` with your app's *Consumer Key*.

```swift
let lockTwitter = LockTwitter(withConsumerKey: "<YOUR CONSUMER KEY>")
```

You can register this handler to a connection name when setting up Lock.


```swift
.handlerAuthentication(forConnectionName: "twitter", handler: lockTwitter)
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
