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

+ (NSNumber*)chairNumberFromString:(NSString*)chairName {
    
    NSString *chairNumberStr = [[chairName componentsSeparatedByCharactersInSet:
                                 [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];

    if ([chairNumberStr length] > 0) {
        chairNumberStr = [chairNumberStr substringToIndex:1];
        return @([chairNumberStr intValue]);
    }
    return @0;
}

+ (NSString*)statusFromVerb:(NSString *)verb{
    //- (ChairStatus) getStatusFromVerb:(NSString *)verb{
    if ([verb isEqualToString:@"checkin"] || [verb isEqualToString:@"approve"]) {
        //        return TAKEN;
        return @"TAKEN";
    }
    else if ([verb isEqualToString:@"leave"] || [verb isEqualToString:@"deny"]) {
        //        return AVAILABLE;
        return @"AVAILABLE";
    }
    else {
        //        return REQUESTED;
        return @"REQUESTED";
    }
}

@end
