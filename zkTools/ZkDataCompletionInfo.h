//
//  ZkDataCompletionInfo.h
//  zkTools
//
//  Created by Nimitz_007 on 2023/3/21.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import "ZkCompletionInfo.h"
#import "zkLib/include/zookeeper.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZkDataCompletionInfo : ZkCompletionInfo

@property (nonatomic) struct Stat *stat;

- (void)setValue:(const char *)value;

- (NSString *)getValue;

@end

NS_ASSUME_NONNULL_END
