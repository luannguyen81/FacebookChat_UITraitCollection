//
//  FCFriendsTVC.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCFriendsTVC.h"
#import "Conversation.h"
#import "FCConversationModel.h"
#import "UIImageView+WebCache.h"
#import "TDBadgedCell.h"
#import "XMPP.h"
#import "Message.h"
#import "NSString+Additions.h"
#import "FCChatDataStoreManager.h"
#import "FCAPIController.h"
#import "FCMessageVC.h"
#import "FCUser.h"

@interface FCFriendsTVC ()
@property (nonatomic, strong) NSMutableArray * offlineUsers;
@property (nonatomic, strong) NSMutableArray * onlineUsers;
@end

@implementation FCFriendsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSArray *allFriends = [Conversation MR_findAll];
    self.offlineUsers = [NSMutableArray arrayWithCapacity:allFriends.count];
    self.onlineUsers = [NSMutableArray arrayWithCapacity:self.onlineFriends.count];
  
  for (Conversation *conversation in allFriends) {
    if ([self isUserIdOnline:conversation.facebookId]) {
      [self.onlineUsers addObject:conversation];
    }else{
      [self.offlineUsers addObject:conversation];
    }
  }
  // sorting
  [self.onlineUsers sortedArrayUsingComparator:^(id obj1, id obj2) {
      NSString *name1 = [[((Conversation *)obj1).facebookName componentsSeparatedByString:@" "] objectAtIndex:0];
      NSString *name2 = [[((Conversation *)obj2).facebookName componentsSeparatedByString:@" "] objectAtIndex:0];
      return[name1 localizedCaseInsensitiveCompare:name2];
    }];
  
  [self.offlineUsers sortedArrayUsingComparator:^(id obj1, id obj2) {
    NSString *name1 = [[((Conversation *)obj1).facebookName componentsSeparatedByString:@" "] objectAtIndex:0];
    NSString *name2 = [[((Conversation *)obj2).facebookName componentsSeparatedByString:@" "] objectAtIndex:0];
    return[name1 localizedCaseInsensitiveCompare:name2];
  }];

    self.title = [NSString stringWithFormat:@"Friends of %@",[FCAPIController sharedInstance].currentUser.name];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
  
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageReceived:)
                                                 name:kFCMessageDidComeNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark Message Notification Recived
- (void)messageReceived:(NSNotification*)textMessage {
    
    XMPPMessage *message = textMessage.object;
    if([message isChatMessageWithBody]) {
        
        NSString *adressString = [NSString stringWithFormat:@"%@",[message fromStr]];
        NSString *newStr = [adressString substringWithRange:NSMakeRange(1, [adressString length]-1)];
        NSString *facebookID = [NSString stringWithFormat:@"%@",[[newStr componentsSeparatedByString:@"@"] objectAtIndex:0]];
        
        NSLog(@"FACEBOOK_ID:%@",facebookID);
        
        // Build the predicate to find the person sought
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"facebookId = %@", facebookID];
        Conversation *conversation = [Conversation MR_findFirstWithPredicate:predicate inContext:localContext];
        
        Message *msg = [Message MR_createInContext:localContext];
        msg.text = [NSString stringWithFormat:@"%@",[[message elementForName:@"body"] stringValue]];
        msg.sentDate = [NSDate date];
        
        // message did come, this will be on left
        msg.messageStatus = @(TRUE);
        
        // increase badge number.
        int badgeNumber = [conversation.badgeNumber intValue];
        badgeNumber++;
        conversation.badgeNumber = [NSNumber numberWithInt:badgeNumber];
        [conversation addMessagesObject:msg];
        [localContext MR_saveOnlySelfAndWait];
        
        [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == 0){
    return self.onlineUsers.count;
  }
  return self.offlineUsers.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == 0){
    return [NSString stringWithFormat:@"Friends online (%d)", self.onlineUsers.count];
  }
  return [NSString stringWithFormat:@"Friends offline (%d)", self.offlineUsers.count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TDBadgedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  Conversation *conversation = nil;
  if (indexPath.section == 0){
   conversation = [self.onlineUsers objectAtIndex:indexPath.row];
    cell.badgeString = @"Online";
    cell.badgeColor = [UIColor greenColor];
    cell.badge.radius = 4;
  
  }
  else{
   conversation = [self.offlineUsers objectAtIndex:indexPath.row];
  
    if([conversation.badgeNumber intValue] != 0) {
        cell.badgeString = [NSString stringWithFormat:@"%@", conversation.badgeNumber];
        cell.badgeColor = [UIColor colorWithRed:0.197 green:0.592 blue:0.219 alpha:1.000];
        cell.badge.radius = 9;
    }
    else {
        cell.badgeString = @"";
        cell.badgeColor = [UIColor clearColor];
        cell.badge.radius = 0;
    }
  
  }
    NSString *url = [[NSString alloc]
                     initWithFormat:@"https://graph.facebook.com/%@/picture",conversation.facebookId];
    [cell.imageView setImageWithURL:[NSURL URLWithString:url]
                   placeholderImage:nil
                          completed:^(UIImage *image, NSError *error, SDImageCacheType type){}];
    cell.textLabel.text = conversation.facebookName;
    return cell;
}

- (BOOL)isUserIdOnline:(NSString*)userId
{
  for (FCUser *user in self.onlineFriends) {
    if ([userId isEqualToString:user.userId]){
      return YES;
    }
  }
  return NO;
}
#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  FCMessageVC *messageVC = [[FCMessageVC alloc] initWithNibName:@"FCMessageVC" bundle:nil];
  if (indexPath.section == 0){
    messageVC.conversation = [self.onlineUsers objectAtIndex:indexPath.row];
  }else{
    messageVC.conversation = [self.offlineUsers objectAtIndex:indexPath.row];
  }
  
  [self showDetailViewController:messageVC sender:self];
}

@end
