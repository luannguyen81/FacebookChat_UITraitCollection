//
//  AppDelegate.m
//  FacebookChat
//
//  Created by Kanybek Momukeyev on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "XMPP.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "FCAPIController.h"
#import "FCChatDataStoreManager.h"
#import "FCLoginVC.h"
#import "FCFriendsTVC.h"
#import "FCMessageVC.h"
#import "UIViewController+Conversation.h"
#import "FCAuthFacebookManager.h"
#import "AAPLTraitOverrideViewController.h"
#import "AAPLEmptyViewController.h"

@interface AppDelegate() <UISplitViewControllerDelegate>
@end
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"MyDatabase.sqlite"];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
    UISplitViewController *controller = [[UISplitViewController alloc] init];
    controller.delegate = self;
  
    FCLoginVC *master = [[FCLoginVC alloc] initWithNibName:@"FCLoginVC" bundle:nil];
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:master];
    
    FCMessageVC *detail = [[FCMessageVC alloc] initWithNibName:@"FCMessageVC" bundle:nil];
    
    controller.viewControllers = @[masterNav, detail];
    controller.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
  
    AAPLTraitOverrideViewController *traitController = [[AAPLTraitOverrideViewController alloc] init];
    traitController.viewController = controller;
    self.window.rootViewController = traitController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[[FCAPIController sharedInstance] chatDataStoreManager] saveContext];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [[[FCAPIController sharedInstance] authFacebookManager] handleOpenURL:url];
}

#pragma mark - Split View Controller

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
  Conversation *conversation = [secondaryViewController aapl_containedConversation];
  if (!conversation) {
    // If our secondary controller doesn't show a photo, do the collapse ourself by doing nothing
    return YES;
  }
  
  // Before collapsing, remove any view controllers on our stack that don't match the photo we are about to merge on
  if ([primaryViewController isKindOfClass:[UINavigationController class]]) {
    NSMutableArray *viewControllers = [NSMutableArray array];
    for (UIViewController *controller in [(UINavigationController *)primaryViewController viewControllers]) {
        [viewControllers addObject:controller];
    }
    [(UINavigationController *)primaryViewController setViewControllers:viewControllers];
  }
  return NO;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
{
  if ([primaryViewController isKindOfClass:[UINavigationController class]]) {
    for (UIViewController *controller in [(UINavigationController *)primaryViewController viewControllers]) {
      if ([controller aapl_containedConversation]) {
        // Do the standard behavior if we have a photo
        return nil;
      }
    }
  }
  // If there's no content on the navigation stack, make an empty view controller for the detail side
  return [[AAPLEmptyViewController alloc] init];
}

@end
