/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A category that returns information about photos contained in view controllers.
  
 */

#import <UIKit/UIKit.h>

@class Conversation;

@interface UIViewController (Conversation)

- (Conversation *)aapl_containedConversation;
- (BOOL)aapl_containsConversation:(Conversation *)photo;
- (Conversation *)aapl_currentVisibleDetailConversationWithSender:(id)sender;

@end
