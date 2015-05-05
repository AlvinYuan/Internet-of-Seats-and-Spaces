//
//  AppDelegate.m
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 3/20/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


static NSString * const kPushServerHost = @"http://serene-wave-9290.herokuapp.com";
static NSString * const kRegisterDevicePath = @"/register_device/";


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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
    return YES;
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *iOSDeviceToken =
    [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
     ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
     ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
     ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:iOSDeviceToken forKey:@"deviceId"];
    [userDefaults synchronize];
    
    [self sendDeviceToken:iOSDeviceToken];
    NSLog(@"Did Register for Remote Notifications with Device Token (%@)", deviceToken);
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Did Fail to Register for Remote Notifications");
    NSLog(@"%@, %@", error, error.localizedDescription);
    
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
