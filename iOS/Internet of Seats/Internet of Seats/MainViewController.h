//
//  ViewController.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 3/20/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

- (IBAction)sendRequestToASBase:(id)sender;
- (IBAction)allowPushNotification:(id)sender;

- (void)sendDeviceToken:(NSString *)deviceToken;

@end

