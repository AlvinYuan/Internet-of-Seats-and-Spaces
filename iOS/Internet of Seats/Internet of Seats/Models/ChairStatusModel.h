//
//  ChairStatusModel.h
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "ChairModel.h"
#import "ObjectModel.h"

@interface ChairStatusModel : ChairModel

@property (strong, nonatomic) ObjectModel *object;

- (id)initWithChairModel:(ChairModel *)chair;

@end
