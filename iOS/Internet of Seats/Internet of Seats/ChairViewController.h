//
//  ChariViewController.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"

@interface ChairViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) MainViewController *delegateController;
@property (strong, nonatomic) NSDictionary *chairs;

@end
