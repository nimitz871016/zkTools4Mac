//
//  ZkDataCompletionInfo.m
//  zkTools
//
//  Created by Nimitz_007 on 2023/3/21.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import "ZkDataCompletionInfo.h"

@interface ZkDataCompletionInfo()

@property (nonatomic, strong, readwrite) NSString *stringValue;

@end

@implementation ZkDataCompletionInfo

- (NSString *)getValue {
    return self.stringValue;
}

- (void)setValue:(const char *)value {
    self.stringValue = [NSString stringWithUTF8String:value];
}

- (void)setStat:(struct Stat *)stat {
    _stat = malloc(sizeof(struct Stat));
    _stat->czxid = stat->czxid;
    _stat->mzxid = stat->mzxid;
    _stat->ctime = stat->ctime;
    _stat->mtime = stat->mtime;
    _stat->version = stat->version;
    _stat->aversion = stat->aversion;
    _stat->cversion = stat->cversion;
    _stat->ephemeralOwner = stat->ephemeralOwner;
    _stat->dataLength = stat->dataLength;
    _stat->numChildren = stat->numChildren;
    _stat->pzxid = stat->pzxid;
}

@end
