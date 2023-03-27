//
//  ZkStringCompletitionInfo.m
//  zkTools
//
//  Created by Nimitz_007 on 2023/3/22.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import "ZkStringCompletitionInfo.h"

@interface ZkStringCompletitionInfo()

@property (nonatomic, strong, readwrite) NSString *stringValue;

@end

@implementation ZkStringCompletitionInfo

- (NSString *)getValue {
    return self.stringValue;
}

- (void)setValue:(const char *)value {
    self.stringValue = [NSString stringWithUTF8String:value];
}

@end
