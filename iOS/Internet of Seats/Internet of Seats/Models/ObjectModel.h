//
//  ObjectModel.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddressModel.h"

@interface ObjectModel : NSObject

@property (strong, nonatomic) AddressModel *address;
@property (strong, nonatomic) NSString* displayName;
@property (strong, nonatomic) NSArray* descriptorTags;
//@property (strong, nonatomic) NSString* id;
@property (strong, nonatomic) NSString* objectType;

@end

//"object":{
//    "address":{
//        "locality":"Berkeley",
//        "region":"CA"
//    },
//    "displayName":"Chair3 in FSM",
//    "descriptor-tags":[
//                       "chair",
//                       " rolling"
//                       ],
//    "id":"http://example.org/fsm/chair/3",
//    "objectType":"place"
//}


