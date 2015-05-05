//
//  ViewController.m
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 3/20/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "MainViewController.h"
#import "FSMViewController.h"
#import "BartViewController.h"

@interface MainViewController ()

@property (strong, nonatomic) NSArray *allowedVerbs;

@end

static NSString * const kChairStatusDownloaded = @"chairStatusDownloaded";

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

typedef enum {
    AVAILABLE,
    REQUESTED,
    TAKEN
} ChairStatus;


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.allowedVerbs = @[kVerbCheckin, kVerbLeave, kVerbReqeust, kVerbApprove, kVerbDeny];
    
    FSMViewController *chairViewController = self.viewControllers[0];
    BartViewController *bartViewController = self.viewControllers[1];
    
    chairViewController.delegateController = self;
    bartViewController.delegateController = self;
    
    // Download initial chair status
    [self downloadInitialChairStatus];
    
}

- (void)downloadInitialChairStatus {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:@{kChairStatusDownloaded: @false}];
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
                    
//                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//                    [userDefaults setBool:kChairStatusDownloaded forKey:true];
//                    [userDefaults synchronize];
                    
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
    [fsmViewController setChairs:categorizedChairs[@"FSM"]];
    BartViewController *bartViewController = self.viewControllers[1];
    [bartViewController setChairs:categorizedChairs[@"BART"]];
//    [self showChairStatus:requests];
    
    [fsmViewController.tableView reloadData];
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
        NSNumber *number = [self getChairNumberFromString:name];
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
            latestChairStatus[chairName] = @{@"published": chair[@"published"], @"status": @([self getStatusFromVerb: chair[@"verb"]])};
        }
    }
    return latestChairStatus;
}

- (NSNumber*) getChairNumberFromString:(NSString*)chairName {
    
    NSString *chairNumberStr = [[chairName componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                           componentsJoinedByString:@""];
    return @([chairNumberStr intValue]);
}

- (ChairStatus) getStatusFromVerb:(NSString *)verb{
    if ([verb isEqualToString:@"checkin"] || [verb isEqualToString:@"approve"]) {
        return TAKEN;
    }
    else if ([verb isEqualToString:@"leave"] || [verb isEqualToString:@"deny"]) {
        return AVAILABLE;
    }
    else {
        return REQUESTED;
    }
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

- (NSDate*)stringToDate:(NSString*)string {
    // Only the first 19 chars: 2015-05-03T01:34:15
    NSString *dateStr = [string substringToIndex:18];
    
    // Convert string to date object
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-d'T'HH:mm:ss"];
    NSDate *date = [dateFormat dateFromString:dateStr];
    return date;
}

- (BOOL)compareDate:(NSString*)dateStr1 earlierThan:(NSString*)dateStr2 {
    NSDate* date1 = [self stringToDate:dateStr1];
    NSDate* date2 = [self stringToDate:dateStr2];
    return [date1 compare:date2] == NSOrderedAscending;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)sendRequestToASBase:(id)sender {
    NSLog(@"Request sent!");
    
    // Send device token to push server
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(globalQ, ^{
        NSURLRequest *searchRequest = [self composeActivityURLWithActor:@"TestSeat" startTime:[NSDate date] endTime:[NSDate date] requestChair:@"Chair"];
        
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:searchRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if (!error && httpResponse.statusCode == 201) {
                NSLog(@"Success: send request");
            } else {
                NSLog(@"Fail");
            }
        }] resume];
    });
}


//"{
//""actor"": {
//    ""displayName"": ""Student Name"",
//    ""objectType"": ""person""
//},
//""verb"": ""request"",
//""startTime"": ""2015-01-06T15:04:55.000Z"",
//""endTime"": ""2015-01-06T15:04:55.000Z"",
//""requestID"":00000000000000001,
//""object"": {
//    ""objectType"": ""place"",
//    ""id"": ""http://example.org/berkeley/southhall/202/chair/1""
//    ""displayName"": ""Chair at 202 South Hall, UC Berkeley"",
//    ""position"": {
//        ""latitude"": 34.34,
//        ""longitude"": -127.23,
//        ""altitude"": 100.05
//    },
//    ""descriptor-tags"": [
//                          ""chair"",
//                          ""rolling""
//                          ]
//}
//}"

- (NSURLRequest *)composeActivityURLWithActor:(NSString *)actorName startTime:(NSDate *) startTime endTime:(NSDate *) endTime requestChair:(NSString *)chiarID {
    
    // TODO: - replace startTime, endTime, requestID, chairID, position, descriptor-tags
    NSDictionary *params = @{
                             @"actor": @{
                                     @"displayName": actorName,
                                     @"objectType": kObjectTypePerson
                                     },
                             @"verb": kVerbReqeust,
                             @"startTime":@"2015-04-27T00:04:55Z",
                             @"endTime":@"2015-04-27T00:04:55Z",
                             @"requestID":@"personID",
                             @"object": @{
                                     @"objectType": kObjectTypePlace,
                                     @"id": @"chairID",
                                     @"displayName": chiarID,
                                     @"position": @{
                                             @"latitude": @"34.34",
                                             @"longitude": @"-127.23",
                                             @"altitude": @"100.05"
                                             }
                                     },
                             @"descriptor-tags": @[@"chair", @"rolling"]
                             };
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kASBaseHost, kActivityPath]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"application/stream+json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    
    return request;
}


@end
