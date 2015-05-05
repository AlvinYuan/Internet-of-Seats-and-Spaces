//
//  CommonHelper.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const kASBaseHost = @"http://russet.ischool.berkeley.edu:8080";
static NSString * const kActivityPath = @"/activities";
static NSString * const kQueryPath = @"/query";
static NSString * const kVerbCheckin = @"checkin";
static NSString * const kVerbLeave = @"leave";
static NSString * const kVerbReqeust = @"request";
static NSString * const kVerbApprove = @"approve";
static NSString * const kVerbDeny = @"deny";

static NSString * const kObjectTypePerson = @"person";
static NSString * const kObjectTypePlace = @"place";

@interface CommonHelper : NSObject

+ (NSDate*)stringToDate:(NSString*)string;
+ (NSString*)currentDateString;

@end
