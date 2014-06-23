//
//  FCLoginVC.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCLoginVC.h"
#import "FCAPIController.h"
#import "FCAuthFacebookManager.h"
#import "FCRequestFacebookManager.h"
#import "FCUser.h"
#import "FCFriendsTVC.h"
#import "FCMessageVC.h"
#import "FCChatDataStoreManager.h"
#import "Sequencer.h"
#import "FCUser.h"

@interface FCLoginVC ()
@property (nonatomic) NSMutableArray *onlineFriends;
@end

@implementation FCLoginVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
      self.onlineFriends = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)loginButtonDidPressed:(id)sender
{
    __weak FCLoginVC *self_ = self;
    [[[FCAPIController sharedInstance] authFacebookManager] authorize];
    [[FCAPIController sharedInstance] authFacebookManager].facebookAuthHandler = ^(NSNumber *sucess, NSError *error){
        if (!error) {
            [self_ runSequncer];
        }
    };
}

- (void)runSequncer
{
    __weak FCLoginVC *self_ = self;
    Sequencer *sequencer = [Sequencer new];
    [sequencer enqueueStep:^(id result, SequencerCompletion completion) {
        
        [[[FCAPIController sharedInstance] requestFacebookManager] requestGraphMeWithCompletion:^(NSDictionary *response, NSError *error){
            if (!error) {
                FCUser *currentUser = [[FCUser alloc] initWithDict:response];
                [[FCAPIController sharedInstance] setCurrentUser:currentUser];
                NSLog(@"This is the first step");
                completion(nil);
            }
        }];
    }];
    
    [sequencer enqueueStep:^(id result, SequencerCompletion completion) {
        
        [[[FCAPIController sharedInstance] requestFacebookManager] requestGraphFriendsWithCompletion:^(NSArray *responseArray, NSError *error) {
            if (!error) {
                [[[FCAPIController sharedInstance] chatDataStoreManager] differenceOfFriendsIdWithNewConversation:responseArray
                                                                                                   withCompletion:^(NSNumber *sucess, NSError *eror){
                                                                                                       if (sucess) {
                                                                                                           NSLog(@"This is second step");
                                                                                                           completion(nil);
                                                                                                       }
                                                                                                   }];
            }
        }];
    }];
  
  [sequencer enqueueStep:^(id result, SequencerCompletion completion) {
    
    [[[FCAPIController sharedInstance] requestFacebookManager] requestGraphOnlineFriendsWithCompletion:^(NSArray *responseArray, NSError *error) {
      if (!error) {
          [responseArray enumerateObjectsUsingBlock:^(NSDictionary *friendDict, NSUInteger idx, BOOL *stop){
            FCUser *user = [[FCUser alloc] initWithOnlineFriendDic:friendDict];
            [self.onlineFriends addObject:user];
          }];
        NSLog(@"This is third step");
        completion(nil);
        }
    }];
  }];
  
    [sequencer enqueueStep:^(id result, SequencerCompletion completion) {
      FCFriendsTVC *friendsTVC = [[FCFriendsTVC alloc] initWithNibName:@"FCFriendsTVC" bundle:nil];
      friendsTVC.onlineFriends = self.onlineFriends;
      [self_.navigationController setViewControllers:@[friendsTVC] animated:YES];
    
      NSLog(@"This is last step");
      completion(nil);
    }];
    
    [sequencer run];
}

@end
