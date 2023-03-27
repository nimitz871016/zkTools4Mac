//
//  ZkStringCompletitionInfo.h
//  zkTools
//
//  Created by Nimitz_007 on 2023/3/22.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import "ZkCompletionInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZkStringCompletitionInfo : ZkCompletionInfo

- (void)setValue:(const char *)value;

- (NSString *)getValue;

@end

NS_ASSUME_NONNULL_END
