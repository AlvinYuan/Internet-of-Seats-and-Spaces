//
//  ChairResultModel.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChairModel.h"

@interface ChairResultModel : ChairModel

@property (strong, nonatomic) ChairModel* object;

- (id)initWithChairModel:(ChairModel *)chair;

@end
