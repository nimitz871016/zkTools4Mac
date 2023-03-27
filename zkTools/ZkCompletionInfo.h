//
//  ZkCompletionInfo.h
//  zkTools
//
//  Created by Nimitz_007 on 2023/3/21.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZkCompletionInfo : NSObject

@property (nonatomic) int rc;

@property (nonatomic, strong) dispatch_semaphore_t sema;

- (NSString *) rc2Desc;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithSema:(dispatch_semaphore_t) sema;

@end

NS_ASSUME_NONNULL_END
