//
//  ZkAddNodeViewController.h
//  zkTools
//
//  Created by Nimitz_007 on 2023/3/22.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZkAddNodeDelegate;

@interface ZkAddNodeViewController : NSViewController

@property (nonatomic, weak) NSString *nodePath;

@property (nonatomic, weak) NSString *nodeName;

@property (nonatomic, weak) NSString *nodeValue;

@property (nonatomic, weak) NSWindowController *windowController;

@property (nullable, assign) id <ZkAddNodeDelegate> delegate;

@end

@protocol ZkAddNodeDelegate <NSObject>

- (void) onNodeAdd:(NSString *) nodeName value:(NSString *) nodeValue;

@end

NS_ASSUME_NONNULL_END
