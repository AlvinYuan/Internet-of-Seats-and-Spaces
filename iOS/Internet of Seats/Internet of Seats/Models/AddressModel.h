//
//  AddressModel.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AddressModel : NSObject

@property (strong, nonatomic) NSString *locality;
@property (strong, nonatomic) NSString *region;

@end


//"address":{
//    "locality":"Berkeley",
//    "region":"CA"
//},
