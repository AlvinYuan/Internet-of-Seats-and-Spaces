//
//  ChairResultModel.m
//  Internet of Seats
//
//  Created by Pi-Tan Hu on 5/4/15.
//  Copyright (c) 2015 LaContra. All rights reserved.
//

#import "ChairResultModel.h"

@implementation ChairResultModel

- (id)initWithChairModel:(ChairModel *)chair {
    self = [super init];
    if(self) {
        self.actor = chair.actor;
        self.provider = chair.provider;
        self.verb = chair.verb;
        self.published = chair.published;
        self.reason = chair.reason;
    }
    return self;
}

@end
