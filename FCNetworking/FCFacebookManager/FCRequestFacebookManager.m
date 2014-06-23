//
//  FCRequestFacebookManager.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCRequestFacebookManager.h"
#import "FCAuthFacebookManager.h"
#import "FCAPIController.h"
#import "IQSocialRequestBaseClient.h"

@implementation FCRequestFacebookManager

- (NSDictionary *)createParamsForCurrentSession
{
    NSDictionary *jsonDictionary2 = @{@"access_token":[[FCAPIController sharedInstance] authFacebookManager].facebook.accessToken};
    return jsonDictionary2;
}

- (void)requestGraphMeWithCompletion:(CompletionBlock)completion
{
    [[IQSocialRequestBaseClient sharedClient] getPath:@"me"
                                           parameters:[self createParamsForCurrentSession]
                                              success:^(AFHTTPRequestOperation *opertaion, id response){
                                                  NSLog(@"%@",response);
                                                  if (completion) {
                                                      completion(response, nil);
                                                  }
                                              }
                                              failure:^(AFHTTPRequestOperation *opertaion, NSError *error){
                                                  NSLog(@"%@",error);
                                                  if (completion) {
                                                      completion(nil, error);
                                                  }
                                              }];
}

- (void)requestGraphFriendsWithCompletion:(CompletionBlock)completion
{
    [[IQSocialRequestBaseClient sharedClient] getPath:@"me/friends"
                                           parameters:[self createParamsForCurrentSession]
                                              success:^(AFHTTPRequestOperation *opertaion, id response){
                                                  NSLog(@"%@",response);
                                                  NSArray *friends = [response objectForKey:@"data"];
                                                  if (completion) {
                                                      completion(friends, nil);
                                                  }
                                              }
                                              failure:^(AFHTTPRequestOperation *opertaion, NSError *error){
                                                  NSLog(@"%@",error);
                                                  if (completion) {
                                                      completion(nil, error);
                                                  }
                                              }];
}

- (void)requestGraphOnlineFriendsWithCompletion:(CompletionBlock)completion
{
  NSString *query =
  @"SELECT uid, name,pic_small,pic_big,online_presence FROM user WHERE online_presence IN ('active') "
  @"AND uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) order by name";
  // Set up the query parameter
  NSMutableDictionary *queryParam = [NSMutableDictionary dictionaryWithObject:query forKey:@"q"];
  [queryParam addEntriesFromDictionary:[self createParamsForCurrentSession]];
  
  [[IQSocialRequestBaseClient sharedClient] getPath:@"/fql"
                                         parameters:queryParam
                                            success:^(AFHTTPRequestOperation *opertaion, id response){
                                              NSLog(@"%@",response);
                                              NSArray *friends = [response objectForKey:@"data"];
                                              if (completion) {
                                                completion(friends, nil);
                                              }
                                            }
                                            failure:^(AFHTTPRequestOperation *opertaion, NSError *error){
                                              NSLog(@"%@",error);
                                              if (completion) {
                                                completion(nil, error);
                                              }
                                            }];
}
@end
