//
//  ChariViewController.m
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "FSMViewController.h"
#import "CommonHelper.h"

@interface FSMViewController ()

@property (strong, nonatomic) NSArray* chairViews;

@end

@implementation FSMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupChairViews];
    [self updateChairStatus];
}

- (void)setupChairViews {
    // Only 6 seats for FSM
    CGRect sizeRect = [UIScreen mainScreen].applicationFrame;
    float width = sizeRect.size.width;
    float height = sizeRect.size.height;
    float circle2Radius = 60;
    
    float distanceW = (width - (circle2Radius)*3) / 4;
    float firstH = (height - (circle2Radius*2 + distanceW)) / 2;
    float secondH = firstH + circle2Radius + distanceW;
    
    NSMutableArray *views = [[NSMutableArray alloc] init];
    
    for (int i = 1; i<4 ; i++) {
        UIButton *chairView1 = [[UIButton alloc] initWithFrame:CGRectMake((circle2Radius*(i-1) + distanceW*i), firstH, circle2Radius, circle2Radius)];
        UIButton *chairView2 = [[UIButton alloc] initWithFrame:CGRectMake((circle2Radius*(i-1) + distanceW*i), secondH, circle2Radius, circle2Radius)];
        
        int index1 = i*2-1;
        int index2 = i*2;
   
        chairView1.alpha = 0.5;
        chairView2.alpha = 0.5;
        
        chairView1.tag = index1;
        chairView2.tag = index2;
        
        chairView1.layer.cornerRadius = circle2Radius/2;
        chairView2.layer.cornerRadius = circle2Radius/2;
        
        [chairView1 addTarget:self action:@selector(sendChairRequest:) forControlEvents:UIControlEventTouchUpInside];
        [chairView2 addTarget:self action:@selector(sendChairRequest:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:chairView1];
        [self.view addSubview:chairView2];
        
        [views addObject:chairView1];
        [views addObject:chairView2];
    }
    self.chairViews = views;
}

- (void)sendChairRequest:(id)sender {
    UIButton *chair = (UIButton*)sender;
    int number = (int)chair.tag;
    
    [self sendRequestToASBase:number];
}

- (void)updateChairStatus {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *serialized = [userDefaults objectForKey:@"FSM"];
    NSDictionary *chairs = [NSKeyedUnarchiver unarchiveObjectWithData:serialized];
    
    for (NSNumber *number in chairs) {
        for (UIButton *view in self.view.subviews) {
            if (view.tag == [number intValue]) {
                UIColor *color = [self colorByChairStatus:chairs[number]];
                [view performSelectorOnMainThread:@selector(setBackgroundColor:) withObject:color waitUntilDone:NO];
            }
        }
    }
}

- (void)sendRequestToASBase:(int)number{
    NSLog(@"Request sent!");
    
    // Send device token to push server
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(globalQ, ^{
        NSString *chairName = [NSString stringWithFormat:@"Chair%d in FSM", number];
        NSURLRequest *searchRequest = [self composeActivityURLWithChair:chairName chairNumber:number];
        
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

- (NSURLRequest *)composeActivityURLWithChair:(NSString*)chair chairNumber:(int)chairNumber{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceId = [userDefaults objectForKey:@"deviceId"];
//    NSString *deviceId = @"testId";
    
    NSDictionary *params = @{
                             @"actor": @{
                                     @"displayName": @"iOS app",
                                     @"objectType": kObjectTypePerson,
                                     @"system": @"iOS",
                                     @"device_id":deviceId
                                         },
                             @"provider": @{
                                     @"displayName": @"BerkeleyChair"
                                     },
                             @"verb": kVerbReqeust,
                             @"published": [CommonHelper currentDateString],
                             @"object": @{
                                     @"address": @{
                                             @"locality": @"Berkeley",
                                             @"region": @"CA"
                                             },
                                     @"displayName": chair,
                                     @"descriptor-tags": @[@"chair", @"rolling"],
                                     @"id": [NSString stringWithFormat:@"http://example.org/fsm/chair/%d", chairNumber],
                                     @"objectType": kObjectTypePlace,
                                     }
                             };
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kASBaseHost, kActivityPath]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"application/stream+json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    return request;
}


- (UIColor*)colorByChairStatus:(NSString*) status {
    if ([status isEqualToString:@"AVAILABLE"]) {
        return [UIColor greenColor];
    }
    if ([status isEqualToString:@"REQUESTED"]) {
        return [UIColor yellowColor];
    }
    if ([status isEqualToString:@"TAKEN"]) {
        return [UIColor redColor];
    }
    return [UIColor whiteColor];
}

//- (UIColor*)colorByChairStatus:(ChairStatus) status{
//    switch (status) {
//        case AVAILABLE:
//            return [UIColor greenColor];
//        case REQUESTED:
//            return [UIColor blueColor];
//        case TAKEN:
//            return [UIColor redColor];
//        default:
//            return [UIColor orangeColor];
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
