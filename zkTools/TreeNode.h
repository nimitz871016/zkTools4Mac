//
//  TreeNode.h
//  zkTools
//
//  Created by Nimitz_007 on 2023/3/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TreeNode : NSObject

@property(nonatomic,strong) NSString *nodeName;//名称
@property(nonatomic,assign) NSInteger count;//子节点个数
@property(nonatomic,assign) BOOL isLeaf;//是否叶子节点
@property(nonatomic,strong) NSArray *children;//子节点

@end

NS_ASSUME_NONNULL_END
