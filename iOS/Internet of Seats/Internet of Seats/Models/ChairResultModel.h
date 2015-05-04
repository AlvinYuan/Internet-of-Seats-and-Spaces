//
//  ChairResultModel.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChairModel.h"
#import "ChairStatusModel.h"

@interface ChairResultModel : ChairModel

@property (strong, nonatomic) ChairStatusModel* object;

- (id)initWithChairModel:(ChairModel *)chair;

@end
