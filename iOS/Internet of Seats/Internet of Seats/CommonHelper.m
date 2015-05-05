//
//  CommonHelper.m
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "CommonHelper.h"

@implementation CommonHelper

+ (NSDate*)stringToDate:(NSString*)string {
    // Only the first 19 chars: 2015-05-03T01:34:15
    NSString *dateStr = [string substringToIndex:18];
    
    // Convert string to date object
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-d'T'HH:mm:ss"];
    NSDate *date = [dateFormat dateFromString:dateStr];
    return date;
}

+ (NSString*)currentDateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    NSString *dateStr= [dateFormatter stringFromDate:[NSDate date]];
    return dateStr;
}


@end
