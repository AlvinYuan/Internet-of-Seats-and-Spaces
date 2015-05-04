//
//  RequestModel.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ActorModel.h"
#import "ProviderModel.h"

@interface ChairModel : NSObject

@property (strong, nonatomic) ActorModel *actor;
@property (strong, nonatomic) ProviderModel *provider;
@property (strong, nonatomic) NSString *verb;
@property (strong, nonatomic) NSString *published;
//@property (strong, nonatomic) NSString *id;
@property (strong, nonatomic) NSString *reason;



//{
//    "actor": {
//        "displayName": "Unknown",
//        "objectType": "person"
//    },
//    "verb": "checkin",
//    "published": "2015-01-06T15:04:55.000Z",
//    "object": {
//        "objectType": "place",
//        "id": "http://example.org/berkeley/southhall/202/chair/1"
//        "displayName": "Chair at 202 South Hall, UC Berkeley",
//        "position": {
//            "latitude": 34.34,
//            "longitude": -127.23,
//            "altitude": 100.05
//        },
//        "address": {
//            "locality": "Berkeley",
//            "region": "CA",
//        },
//        "descriptor-tags": [
//                            "chair",
//                            "rolling"
//                            ]
//    },
//    "provider": {
//        "displayName": "BerkeleyChair"
//    }
//}

@end
