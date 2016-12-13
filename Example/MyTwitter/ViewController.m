//
//  ViewController.m
//  MyTwitter
//
//  Created by Hernan Zalazar on 12/7/16.
//  Copyright © 2016 Hernan Zalazar. All rights reserved.
//

#import "ViewController.h"
#import <Lock/Lock.h>
#import <Lock-Twitter/A0TwitterAuthenticator.h>

@interface ViewController ()
@property (strong, nonatomic) A0TwitterAuthenticator *authenticator;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Auth0" ofType:@"plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:path];
    A0Lock *lock = [A0Lock sharedLock];
    self.authenticator = [A0TwitterAuthenticator newAuthenticatorWithConsumerKey:info[@"TwitterConsumerKey"]];
    self.authenticator.clientProvider = lock;
}

- (IBAction)login:(id)sender {
    [self.authenticator authenticateWithParameters:[A0AuthParameters newDefaultParams] success:^(A0UserProfile * _Nonnull profile, A0Token * _Nonnull token) {
        NSLog(@"SUCCESS");
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Failed with error %@", error);
    }];
}

@end
