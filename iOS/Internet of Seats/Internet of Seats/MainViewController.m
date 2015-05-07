//
//  ViewController.m
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 3/20/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "FSMViewController.h"
#import "BartViewController.h"
#import "CommonHelper.h"

@interface MainViewController ()

@property (strong, nonatomic) NSArray *allowedVerbs;

@end

static NSString * const kChairStatusDownloaded = @"chairStatusDownloaded";

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.tabBarController = self;
    
    self.allowedVerbs = @[kVerbCheckin, kVerbLeave, kVerbReqeust, kVerbApprove, kVerbDeny];
    
    // Download initial chair status
    [self downloadInitialChairStatus];
}

- (void)downloadInitialChairStatus {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:@{kChairStatusDownloaded: @false}];
    [userDefaults setBool:false forKey:kChairStatusDownloaded];
    [userDefaults synchronize];
    
    if(![userDefaults boolForKey:kChairStatusDownloaded]) {
        dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(globalQ, ^{
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kASBaseHost, kQueryPath]];
            NSMutableURLRequest *searchRequest = [NSMutableURLRequest requestWithURL:url];
            [searchRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [searchRequest setHTTPMethod:@"GET"];
            
            
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithRequest:searchRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                
                if (!error && httpResponse.statusCode == 200) {
                    NSLog(@"Success: succuss download inital chair status");
                    
                    NSMutableDictionary *innerJson = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                    [self processChairStatus: innerJson];
                    
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults setBool:false forKey:kChairStatusDownloaded];
                    [userDefaults synchronize];
                    
                } else {
                    NSLog(@"Fail:%ld", (long)httpResponse.statusCode);
                }
            }] resume];
            
        });
    }
}

- (void)processChairStatus:(NSDictionary*) queryResult{
    NSArray *allChairsStatus = [self retrieveAllChairStatus: [queryResult objectForKey:@"items"]];
    NSDictionary *latestChairStatus = [self latestChairStatus: allChairsStatus];
    NSDictionary *categorizedChairs = [self categorizeChairs:latestChairStatus];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:categorizedChairs[@"FSM"]] forKey:@"FSM"];
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:categorizedChairs[@"BART"]]  forKey:@"BART"];
    [userDefaults synchronize];
    
    FSMViewController *fsmViewController = self.viewControllers[0];
//    [fsmViewController setChairs:categorizedChairs[@"FSM"]];
//    BartViewController *bartViewController = self.viewControllers[1];
//    [bartViewController setChairs:categorizedChairs[@"BART"]];
 
    [fsmViewController updateChairStatus];
}

/*
 Return dictionary of chair status
 FSM: {chairNumber: status}, ...
 BART: {chairNumber: status}, ...
 */
- (NSDictionary *)categorizeChairs:(NSDictionary *)chairStatus{
    NSMutableDictionary *categorizedChairs = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *fsmChairs = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *bartChairs = [[NSMutableDictionary alloc] init];
    
    for (NSString *name in chairStatus) {
        NSNumber *number = [CommonHelper chairNumberFromString:name];
        if ([[name uppercaseString] containsString:@"FSM"]) {
            fsmChairs[number] = chairStatus[name][@"status"];
        }
        else if([[name uppercaseString] containsString:@"BART"]) {
            bartChairs[number] = chairStatus[name][@"status"];
        }
    }
    
    categorizedChairs[@"FSM"] = fsmChairs;
    categorizedChairs[@"BART"] = bartChairs;
    
    return categorizedChairs;
}

/*
 Return array of chair status
 chairName: {published: time, status: status},
 */
- (NSDictionary *)latestChairStatus:(NSArray *)allChairStatus {
    NSMutableDictionary *latestChairStatus = [[NSMutableDictionary alloc] init];
    for (NSDictionary *chair in allChairStatus) {
        NSString *chairName = chair[@"name"];
        NSDictionary *currentChairStatus = latestChairStatus[chairName];
        BOOL replaceCurrentChairStatus = !currentChairStatus;
        if (currentChairStatus) {
            // Compare the published time
            replaceCurrentChairStatus = [self compareDate:currentChairStatus[@"published"] earlierThan:chair[@"published"]];
        }
        
        if (replaceCurrentChairStatus) {
            latestChairStatus[chairName] = @{@"published": chair[@"published"], @"status": [CommonHelper statusFromVerb: chair[@"verb"]]};
        }
    }
    return latestChairStatus;
}

/*
 Return array of chair status
 [{name:chairName, published: time, verb: verb}, ...]
*/
- (NSArray *)retrieveAllChairStatus:(NSDictionary *)rawChairsData{
    NSMutableArray *allChairStatus = [[NSMutableArray alloc] init];
    for (NSDictionary *chairData in rawChairsData) {
        NSString *verb = chairData[@"verb"];
        if (verb && [self.allowedVerbs containsObject:verb]) {
            NSString *publishedTime = chairData[@"published"];
            NSString *chairName;
            
            if ([verb isEqualToString:@"checkin"] || [verb isEqualToString:@"leave"] || [verb isEqualToString:kVerbReqeust]) {
                if (chairData[@"object"]) {
                    chairName =chairData[@"object"][@"displayName"];
                }
            }
            else if([verb isEqualToString:@"approve"] || [verb isEqualToString:@"deny"]) {
                if (chairData[@"object"] && chairData[@"object"][@"object"]) {
                    chairName =chairData[@"object"][@"object"][@"displayName"];
                }
            }
            if (chairName && publishedTime && [[chairName lowercaseString] containsString:@"chair"]) {
                [allChairStatus addObject:@{@"name": chairName, @"published": publishedTime, @"verb": verb}];
            }
        }
    }
    return allChairStatus;
}


- (BOOL)compareDate:(NSString*)dateStr1 earlierThan:(NSString*)dateStr2 {
    NSDate* date1 = [CommonHelper stringToDate:dateStr1];
    NSDate* date2 = [CommonHelper stringToDate:dateStr2];
    return [date1 compare:date2] == NSOrderedAscending;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
