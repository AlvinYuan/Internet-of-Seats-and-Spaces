//
//  ActorModel.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActorModel : NSObject

@property (strong, nonatomic) NSString *system;
@property (strong, nonatomic) NSString *deviceId;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) NSString *objectType;
@property (strong, nonatomic) NSString *team;

@end

//"actor":{
//    "system":"android",
//    "device_id":"APA91bEKvxn-y2oGlUDvGEZw9cpDCHYS0AukuelvEd2taXEMpZ7rMKJQfiYPK_viwuI19kCTOkj3JKBQBPFjb6w4WDeD1696U_G7picM0yKZ027a3tuVeyZ7_LdVAqrUe0GiRGv25sNpZe5DplbC5yRYAK9LL3_KeA",
//    "displayName":"Android App",
//    "objectType":"person"
//},
