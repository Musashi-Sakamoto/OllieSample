//
//  RKWebAsyncRequestFactory.h
//  RobotKitLE
//
//  Created by Hunter Lang on 7/11/14.
//  Copyright (c) 2014 Orbotix Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kAppId                  @"sphe172c542260dd83c709eba5a449efe59a"
#define kSecret                 @"yKqlueWG2GLVyrAkcAn6"

@interface RKURLRequestFactory : NSObject

+ (NSURLRequest *)requestWithURL:(NSURL *)URL stats:(NSArray *)stats;

@end
