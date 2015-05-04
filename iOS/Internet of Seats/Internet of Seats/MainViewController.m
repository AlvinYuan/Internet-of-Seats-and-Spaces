//
//  ViewController.m
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 3/20/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "MainViewController.h"
#import "ChairViewController.h"
//#import "FSMViewController.h"
#import "BartViewController.h"
//#import "QueryResultModel.h"
#import "ChairStatusModel.h"
#import "ChairResultModel.h"

@interface MainViewController ()

@end

static NSString * const kChairStatusDownloaded = @"chairStatusDownloaded";

static NSString * const kASBaseHost = @"http://russet.ischool.berkeley.edu:8080";
static NSString * const kActivityPath = @"/activities";
static NSString * const kQueryPath = @"/query";
static NSString * const kVerbReqeust = @"request";

static NSString * const kObjectTypePerson = @"person";
static NSString * const kObjectTypePlace = @"place";


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.testV = 5;
    
//    ChairViewController *chairViewController = self.viewControllers[0];
//    BartViewController *bartViewController = self.viewControllers[1];
//    
//    chairViewController.delegateController = self;
//    bartViewController.delegateController = self;

    for (ChairViewController *viewController in self.viewControllers) {
        viewController.delegateController = self;
    }
    
    
    // Download initial chair status
    [self downloadInitialChairStatus];
    
}

- (void)downloadInitialChairStatus {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:@{kChairStatusDownloaded: @false}];
    [userDefaults synchronize];
    
    if(![userDefaults boolForKey:kChairStatusDownloaded]) {
        // Send device token to push server
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
//                    NSArray *queryResults = [QueryResultModel arrayOfModelsFromData:data error:&error];
//                    
//                    QueryResultModel *queryResultModel = nil;
//                    if ([queryResults count] != 0) {
//                        queryResultModel = queryResults[0];
//                        [self processChairStatus: queryResultModel];
//                    }
                    
                    
                    NSMutableDictionary *innerJson = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                    [self processChairStatus: innerJson];
                    
//                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//                    [userDefaults setBool:kChairStatusDownloaded forKey:true];
                    
                } else {
                    NSLog(@"Fail:%ld", (long)httpResponse.statusCode);
                }
            }] resume];
            
        });
    }
}

- (void)processChairStatus:(NSDictionary*) queryResult{
    NSArray *items = queryResult[@"items"];
    NSMutableArray *chairs = [[NSMutableArray alloc] init];
    for (NSDictionary *query in items) {
        if ([query objectForKey:@"verb"]) {
            NSString *verb = [query objectForKey:@"verb"];
            
            if ([verb isEqualToString:@"checkin"] || [verb isEqualToString:@"leave"] || [verb isEqualToString:kVerbReqeust]) {
                ChairStatusModel *chairStatusModel = [self dictToChairStatusModel:query];
                [chairs addObject:chairStatusModel];
            }
//            else if ([verb isEqualToString:@"cancel"]) {
//            }
            else if ([verb isEqualToString:@"deny"] || [verb isEqualToString:@"approve"]) {
                ChairResultModel *chairResultModel = [self dictToChairResultModel:query];
                [chairs addObject:chairResultModel];
            }
            
//            if ([query objectForKey:@"object"]) {
//                NSDictionary *object = [query objectForKey:@"object"];
//                if ([object objectForKey:@"descriptor-tags"]) {
//                    NSArray *tags = [object objectForKey:@"descriptor-tags"];
//                    if ([tags containsObject:@"chair"]) {
//                        [chairs addObject:query];
//                    }
//                }
//            }
        }
    }

    
    ChairViewController *chairViewController = self.viewControllers[0];
    [chairViewController setChairs:chairs];
//    [self showChairStatus:requests];
}

- (ChairModel*)dictToChairModel:(NSDictionary*) data {
    ChairModel *chairModel = [[ChairModel alloc] init];
    
    chairModel.verb = [data objectForKey:@"verb"];
    if ([data objectForKey:@"actor"]) {
        chairModel.actor = [self dictToActorModel:[data objectForKey:@"actor"]];
    }
    if ([data objectForKey:@"provider"]) {
        chairModel.provider = [self dictToProviderModel:[data objectForKey:@"provider"]];
    }
    if ([data objectForKey:@"published"]) {
        chairModel.published = [data objectForKey:@"published"];
    }
    if ([data objectForKey:@"reason"]) {
        chairModel.reason = [data objectForKey:@"reason"];
    }
    
    return chairModel;
}

- (ChairStatusModel*)dictToChairStatusModel:(NSDictionary*) data {
    ChairStatusModel *chairModel = [[ChairStatusModel alloc] initWithChairModel:[self dictToChairModel:data]];
    
    if ([data objectForKey:@"object"]) {
        chairModel.object = [self dictToObjectModel:[data objectForKey:@"object"]];
    }
    
    return chairModel;
}

- (ChairResultModel*)dictToChairResultModel:(NSDictionary*) data {
    ChairResultModel *chairModel = [[ChairResultModel alloc] initWithChairModel:[self dictToChairModel:data]];
    
    if ([data objectForKey:@"object"]) {
        chairModel.object = [self dictToChairStatusModel:[data objectForKey:@"object"]];
    }
    
    return chairModel;
}

- (ObjectModel*)dictToObjectModel:(NSDictionary*) data {
    ObjectModel *objectModel = [[ObjectModel alloc] init];

    
    if ([data objectForKey:@"address"]) {
        objectModel.address = [self dictToAddressModel:[data objectForKey:@"address"]];
    }
    if ([data objectForKey:@"displayName"]) {
        objectModel.displayName = [data objectForKey:@"displayName"];
    }
    if ([data objectForKey:@"descriptor-tags"]) {
        objectModel.descriptorTags = [data objectForKey:@"descriptor-tags"];
    }
    if ([data objectForKey:@"objectType"]) {
        objectModel.descriptorTags = [data objectForKey:@"objectType"];
    }
    return objectModel;
}

- (AddressModel*)dictToAddressModel:(NSDictionary*) data {
    AddressModel *addressModel = [[AddressModel alloc] init];
    if ([data objectForKey:@"locality"]) {
        addressModel.locality = [data objectForKey:@"locality"];
    }
    if ([data objectForKey:@"region"]) {
        addressModel.region = [data objectForKey:@"region"];
    }
    return addressModel;
}

- (ProviderModel*)dictToProviderModel:(NSDictionary*) data {
    ProviderModel *providerModel = [[ProviderModel alloc] init];
    if ([data objectForKey:@"displayName"]) {
        providerModel.displayName = [data objectForKey:@"displayName"];
    }
    return providerModel;
}

- (ActorModel*)dictToActorModel:(NSDictionary*) data {
    ActorModel *actorModel = [[ActorModel alloc] init];
    if ([data objectForKey:@"displayName"]) {
        actorModel.displayName = [data objectForKey:@"displayName"];
    }
    if ([data objectForKey:@"objectType"]) {
        actorModel.displayName = [data objectForKey:@"objectType"];
    }
    if ([data objectForKey:@"device_id"]) {
        actorModel.deviceId = [data objectForKey:@"device_id"];
    }
    if ([data objectForKey:@"system"]) {
        actorModel.system = [data objectForKey:@"system"];
    }
    if ([data objectForKey:@"team"]) {
        actorModel.team = [data objectForKey:@"team"];
    }
    return actorModel;
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
