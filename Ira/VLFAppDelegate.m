//
//  VLFAppDelegate.m
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFAppDelegate.h"

#import "VLFViewController.h"

@implementation VLFAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[VLFViewController alloc] initWithNibName:@"VLFViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self.viewController turnOffAudioGraph];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self.viewController turnOffAudioGraph];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self.viewController restartAudioGraph];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.viewController restartAudioGraph];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.viewController turnOffAudioGraph];
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
