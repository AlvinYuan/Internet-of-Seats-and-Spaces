//
//  ViewController.m
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 3/20/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

static NSString * const kASBaseHost = @"http://russet.ischool.berkeley.edu:8080";
static NSString * const kActivityPath = @"/activities";
static NSString * const kVerbReqeust = @"request";

static NSString * const kObjectTypePerson = @"person";
static NSString * const kObjectTypePlace = @"place";


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)sendRequestToASBase:(id)sender {
    dispatch_group_t requestGroup = dispatch_group_create();
    
    dispatch_group_enter(requestGroup);
    [self postRequestToASbase:^(NSDictionary *topBusinessJSON, NSError *error) {
        
        // TODO: check if there is any error and the response data correct
        dispatch_group_leave(requestGroup);
    }];
    
    dispatch_group_wait(requestGroup, DISPATCH_TIME_FOREVER); // This avoids the program exiting before all our asynchronous callbacks have been made.
    
}


- (void)postRequestToASbase:(void (^)(NSDictionary *topBusinessJSON, NSError *error))completionHandler {
    
    NSURLRequest *searchRequest = [self _composeActivityURLWithActor:@"TestSeat" startTime:[NSDate date] endTime:[NSDate date] requestChair:@"Chair"];
    
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:searchRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (!error && httpResponse.statusCode == 201) {
            NSLog(@"Success");
            
            // TODO: check if the response data is correct, if it's not, callcompletionHandler(nil, error)
        } else {
            NSLog(@"Fail");
            completionHandler(nil, error); // An error happened or the HTTP response is not a 201 OK
        }
    }] resume];
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

- (NSURLRequest *)_composeActivityURLWithActor:(NSString *)actorName startTime:(NSDate *) startTime endTime:(NSDate *) endTime requestChair:(NSString *)chiarID {
    
    // TODO: - replace startTime, endTime, requestID, chairID, position, descriptor-tags
    NSDictionary *params = @{
                             @"actor": @{
                                     @"displayName": actorName,
                                     @"objectType": kObjectTypePerson
                                     },
                             @"verb": kVerbReqeust,
                             @"startTime":@"2015-03-10T00:04:55Z",
                             @"endTime":@"2015-03-11T00:04:55Z",
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
