//
//  ViewController.m
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 3/20/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"

@interface MainViewController ()

@end

static NSString * const kASBaseHost = @"http://russet.ischool.berkeley.edu:8080";
static NSString * const kActivityPath = @"/activities";
static NSString * const kVerbReqeust = @"request";

static NSString * const kObjectTypePerson = @"person";
static NSString * const kObjectTypePlace = @"place";


static NSString * const kPushServerHost = @"http://serene-wave-9290.herokuapp.com";
static NSString * const kRegisterDevicePath = @"/register_device/";


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.viewController = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



- (IBAction)allowPushNotification:(id)sender {
    // Register for Remote Notifications
    if([[UIApplication sharedApplication]  respondsToSelector:@selector(registerUserNotificationSettings:)]){
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
        [[UIApplication sharedApplication]  registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication]  registerForRemoteNotifications];
    }
    else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert| UIRemoteNotificationTypeBadge |  UIRemoteNotificationTypeSound)];
    }
}

- (void)sendDeviceToken:(NSString *)deviceToken {
    // Send device token to push server
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(globalQ, ^{
        NSDictionary *params = @{
                                 @"device_token":deviceToken,
                                 @"system":@"iOS",
                                 };
        
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kPushServerHost, kRegisterDevicePath]];
        NSMutableURLRequest *searchRequest = [NSMutableURLRequest requestWithURL:url];
        [searchRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [searchRequest setHTTPMethod:@"POST"];
        [searchRequest setHTTPBody:jsonData];
     
        
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:searchRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if (!error && httpResponse.statusCode == 200) {
                NSLog(@"Success: send device token");
                
            } else {
                NSLog(@"Fail:%ld", (long)httpResponse.statusCode);
            }
        }] resume];

    });
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
