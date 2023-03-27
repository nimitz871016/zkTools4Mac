//
//  ZkCompletionInfo.m
//  zkTools
//
//  Created by Nimitz_007 on 2023/3/21.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import "ZkCompletionInfo.h"

@implementation ZkCompletionInfo

- (instancetype)initWithSema:(dispatch_semaphore_t)sema {
    self = [super init];
    if (self) {
        self.sema = sema;
    }
    return self;
}

- (NSString *)rc2Desc {
    return nil;
}

@end
