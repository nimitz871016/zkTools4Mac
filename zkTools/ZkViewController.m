//
//  ViewController.m
//  zkTools
//
//  Created by Nimitz_007 on 2021/7/11.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import "ZkViewController.h"
#import "zkLib/include/zookeeper.h"
#import "NodeInfo.h"
#import "ZkDataCompletionInfo.h"
#import "ZkStringCompletitionInfo.h"
#import "ZkAddNodeViewController.h"

@interface ZkViewController()<NSOutlineViewDelegate, NSOutlineViewDataSource, ZkAddNodeDelegate>{
    NSMutableDictionary *currentNode;
}

@property (nonatomic, strong) NSString *oldNodeValue;

@end

@implementation ZkViewController
ZkViewController *thisClass;
dispatch_semaphore_t sema;
zhandle_t *zhandle;
dispatch_queue_t serialQueue1;

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    thisClass = self;
    [self setLogContent:[NSMutableString string]];
    serialQueue1 = dispatch_queue_create("zookeeper", DISPATCH_QUEUE_CONCURRENT);
    return self;
}

void void_completition(int rc, const void *data) {
    NSLog(@"void_completition : %d", rc);
    ZkCompletionInfo *info = ((__bridge ZkCompletionInfo *)data);
    dispatch_semaphore_signal(info.sema);
}

void state_completition(int rc, const struct Stat *stat,
                        const void *data){
    NSLog(@"state_completition : %d", rc);
    if (rc == ZOK) {
        NSLog(@"success");
        dispatch_sync(dispatch_get_main_queue(), ^{
            [thisClass refreshStat:stat];
        });
    } else if (rc == ZBADVERSION){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"修订节点值失败，版本冲突！"];
            [alert setAlertStyle:NSAlertStyleCritical];
            [alert runModal];
        });
    }
    dispatch_semaphore_signal(sema);
}

void data_completition(int rc, const char *value, int value_len,
      const struct Stat *stat, const void *data){
    assert(data != nil);
    ZkDataCompletionInfo *info = ((__bridge ZkDataCompletionInfo *)data);
    if (rc == ZOK) {
        [info setRc:rc];
        [info setValue:value];
        [info setStat:stat];
    } else {
        NSLog(@"data_completition failed %d", rc);
    }
    dispatch_semaphore_signal(info.sema);
}

void string_completition(int rc, const char *value, const void *data) {
    NSLog(@"string_completition :%d, %s", rc, value);
    ZkStringCompletitionInfo *info = ((__bridge ZkStringCompletitionInfo *)data);
    if (rc == ZOK) {
        [info setValue:value];
    }
    dispatch_semaphore_signal(info.sema);
}

void strings_completition(int rc,
                         const struct String_vector *strings, const void *data){
//    NSLog(@"strings_completition rc:%d", rc);
    if (rc == ZCONNECTIONLOSS) {
        
    } else if (rc == ZOPERATIONTIMEOUT) {
        
    } else {
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < strings->count; i++) {
//            NSLog(@"%s", strings->data[i]);
            array[i] = [[NSString alloc] initWithUTF8String:strings->data[i]];
        }
        
//        [((__bridge NSMutableArray *)data) insertObject:@"test" atIndex:0];
        ((__bridge NodeInfo *)data).path = array;
        dispatch_semaphore_signal(sema);
    }
}

void watcher(zhandle_t *zh, int type,
             int state, const char *path,void *watcherCtx) {
    NSLog(@"watch type:%d, state:%d, path:%s", type, state, path);
    __block NSString* pathStr = [NSString stringWithUTF8String:path];
    if (type == ZOO_SESSION_EVENT) {
        if (state == ZOO_CONNECTED_STATE) {
//            连接成功
            NSLog(@"connect success!");
            [thisClass setNotConnected:NO];
        } else {
            [thisClass setNotConnected:YES];
            if (state == ZOO_NOTCONNECTED_STATE) {
                NSLog(@"connect failed!");
                
            } else if (state == ZOO_EXPIRED_SESSION_STATE) {
                NSLog(@"session expired!");
            } else {
                NSLog(@"unknown state! %d", state);
            }
        }
        dispatch_semaphore_signal(sema);
    } else if (type == ZOO_CREATED_EVENT) {
        // 节点创建
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *str = [NSString stringWithFormat:@"%@: 添加一个节点:%@", [NSDate date], pathStr];
            if (thisClass.logContent.length == 0) {
                [thisClass setLogContent:[NSString stringWithFormat:@"%@\n", str]];
            } else {
                [thisClass setLogContent:[NSString stringWithFormat:@"%@%@", thisClass.logContent, str]];
            }
        });
    } else if (type == ZOO_DELETED_EVENT) {
        // 节点删除
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *str = [NSString stringWithFormat:@"%@: 删除一个节点:%@", [NSDate date], pathStr];
            if (thisClass.logContent.length == 0) {
                [thisClass setLogContent:[NSString stringWithFormat:@"%@\n", str]];
            } else {
                [thisClass setLogContent:[NSString stringWithFormat:@"%@%@", thisClass.logContent, str]];
            }
        });
    } else if (type == ZOO_CHANGED_EVENT) {
        // 节点变更
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *str = [NSString stringWithFormat:@"%@: 节点信息变更:%@", [NSDate date], pathStr];
            if (thisClass.logContent.length == 0) {
                [thisClass setLogContent:[NSString stringWithFormat:@"%@\n", str]];
            } else {
                [thisClass setLogContent:[NSString stringWithFormat:@"%@%@", thisClass.logContent, str]];
            }
        });
    } else if (type == ZOO_CHILD_EVENT) {
        // 节点子节点
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [thisClass findNodeByPath:[pathStr UTF8String]];
            [thisClass.treeController removeObjectAtArrangedObjectIndexPath:indexPath];
            [thisClass.treeController insertObject:[thisClass getChildrenOfZk:zhandle path:[pathStr UTF8String] depth:-1] atArrangedObjectIndexPath:indexPath];
        });
    } else if (type == ZOO_NOTWATCHING_EVENT) {
        // 不再监听
    } else {
        NSLog(@"unknown type:%d, state:%d", type, state);
    }
}

- (IBAction)onConnect:(id)sender {
    NSLog(@"sender:%@", self.urlTf.stringValue);
    [self showLoading:YES];
    [self.urlTf setEnabled:NO];
    __block const char *url = [self.urlTf.stringValue UTF8String];
    dispatch_async(serialQueue1, ^{
//        [NSThread sleepForTimeInterval:5];
        sema = dispatch_semaphore_create(0);
        zhandle = zookeeper_init(url, watcher, 10000, NULL, NULL, 0);
        intptr_t result = dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 10));
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showLoading:NO];
            if (zhandle == nil || result != 0) {
                NSLog(@"failed");
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"连接失败"];
                [alert setAlertStyle:NSAlertStyleCritical];
                [alert runModal];
                if (result != 0) {
                    [self onClickDisConnect:nil];
                }
            } else {
                if (self.notConnected) {
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setAlertStyle:NSAlertStyleCritical];
                    [alert setMessageText:@"连接失败"];
                    [alert runModal];
                } else {
                    [self.connectBtn setEnabled:NO];
                    // 读取目录
//                    NSMutableArray *treeNodes = [NSMutableArray array];
//                    [treeNodes addObject:[self getChildrenOfZk:result path:"/" depth:2]];
//                    [self setTreeNodes:treeNodes];
//                    [self.treeNodes replaceObjectAtIndex:0 withObject:[self getChildrenOfZk:result path:"/" depth:2]];
                    [self refreshRootPath:@"/"];
                }
            }
        });
    });
}

- (IBAction)onClickDisConnect:(id)sender {
    if (zhandle != nil) {
        zookeeper_close(zhandle);
        zhandle = nil;
    } else {
        NSLog(@"zhandle nil, maybe zk client is already closed");
    }
    [self.urlTf setEnabled:YES];
    [self setNotConnected:YES];
    [self setCurrentNodeName:nil];
    [self setCurrentNodeValue:nil];
    [self setTreeNodes:nil];
    [self setCurrentCzxid:nil];
    [self setCurrentMzxid:nil];
    [self setCurrentCtime:nil];
    [self setCurrentMtime:nil];
    [self setCurrentVersion:nil];
    [self setCurrentAVersion:nil];
    [self setCurrentCVersion:nil];
    [self setCurrentephemeralOwner:nil];
    [self setCurrentDataLength:nil];
    [self setCurrentNumChildren:nil];
    [self setCurrentPzxid:nil];
}



- (IBAction)onClickCell:(id)sender {
    if (self.selectionIndexPaths.count != 0) {
        currentNode = [self nodeForIndexPath:self.selectionIndexPaths[0]];
        NSLog(@"%s", [currentNode[@"path"] UTF8String]);
        [self setCurrentNodeName:currentNode[@"name"]];
        ZkDataCompletionInfo *info = [[ZkDataCompletionInfo alloc] initWithSema:dispatch_semaphore_create(0)];
        zoo_aget(zhandle, [currentNode[@"path"] UTF8String], 0, data_completition, (__bridge const void *)(info));
        dispatch_semaphore_wait(info.sema, DISPATCH_TIME_FOREVER);
        [self refreshStat:info.stat];
        [self setCurrentNodeValue:info.getValue];
        [self setOldNodeValue:info.getValue];
    }
}

/**
    提交节点值修订
 */
- (IBAction)onClickSubmit:(id)sender {
    // check长度
    dispatch_async(serialQueue1, ^{
        zoo_aset(zhandle, ((NSString *)self->currentNode[@"path"]).UTF8String, self.currentNodeValue.UTF8String, (int)[self.currentNodeValue lengthOfBytesUsingEncoding:NSUTF8StringEncoding], self.currentVersion.intValue, state_completition, nil);
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    });
}

- (IBAction)resetNodeValue:(id)sender {
    [self setCurrentNodeValue:self.oldNodeValue];
}


- (IBAction)onClickRefresh:(id)sender {
    [self refreshRootPath:@"/"];
}

- (IBAction)onClickRemoveNode:(id)sender {
    NSLog(@"remove node at path: %@", currentNode[@"path"]);
    ZkCompletionInfo *info = [[ZkCompletionInfo alloc] initWithSema:dispatch_semaphore_create(0)];
    zoo_adelete(zhandle, [currentNode[@"path"] UTF8String], -1, void_completition, (__bridge const void *)(info));
    dispatch_semaphore_wait(info.sema, DISPATCH_TIME_FOREVER);
}

- (IBAction)onClickSearch:(id)sender {
    NSDictionary *treeNode = self.treeNodes.count > 0 ? self.treeNodes[0] : nil;
    if (treeNode == nil) {
        return;
    }
    // 遍历目录所有节点，找寻匹配的关键词
    NSMutableArray *indexPaths = [NSMutableArray array];
    [self fuzzyFindNode:treeNode value:self.searchValue path:[NSIndexPath indexPathWithIndex:0] result:indexPaths];
    NSLog(@"search result: %@", indexPaths);
    [self setSelectionIndexPaths:indexPaths];
}

- (void) fuzzyFindNode:(NSDictionary *)node
                 value:(NSString *) value
                  path:(NSIndexPath *) curPath
                result:(NSMutableArray<__kindof NSIndexPath *> *) indexPaths {
    if (node == nil || value == nil) {
        return;
    } else {
        NSArray *children = node[@"children"];
        if (children != nil) {
            for (int i = 0; i < children.count; i++) {
                NSDictionary *curNode = children[i];
                [self fuzzyFindNode:curNode value:value path:[curPath indexPathByAddingIndex:i] result:indexPaths];
            }
        }
        if ([node[@"name"] containsString:value]) {
            [indexPaths addObject:curPath];
        }
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.urlTf setPlaceholderString:@"localhost:2181"];
    [self setNotConnected:YES];
    // Do any additional setup after loading the view.
    [self.maskView setWantsLayer:YES];
    
    [self.maskView.layer setBackgroundColor:CGColorCreateSRGB(33, 33, 33, 0.8)];
    [self.maskView setHidden:YES];
    
    [self setLoading:NO];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSLog(@"tableViewSelectionDidChange%@", notification);
}

- (void)outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn {
    NSLog(@"didClickTableColumn");
}

- (void) refreshRootPath:(NSString *)rootPath {
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:[self getChildrenOfZk:zhandle path:[rootPath UTF8String] depth:-1]];
    [self setTreeNodes:array];
}

/**
    获取zk的子节点信息。根据输入的根节点，获取当前节点的子节点信息。需要识别每个子节点是否有子节点。
    @param path 根路径
 */
- (NSMutableDictionary *) getChildrenOfZk:(zhandle_t *)zh path:(const char *)path depth:(int) depth {
//    NSLog(@"get children of path:%s", path);
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
//    node[@"name"] = [NSString stringWithUTF8String:path];
    NSString *name = [NSString stringWithUTF8String:path];
    node[@"path"] = [name copy];
//    NSLog(@"name:%@", [name substringFromIndex:[name rangeOfString:@"/" options:NSBackwardsSearch].location + 1]);
    if (strcmp(path, "/") == 0) {
        node[@"name"] = @"/";
    } else {
        node[@"name"] = [name substringFromIndex:[name rangeOfString:@"/" options:NSBackwardsSearch].location + 1];
    }
    NodeInfo *nodeInfo = [[NodeInfo alloc] init];
    if (zoo_aget_children(zh, path, 1, strings_completition, (__bridge const void *)(nodeInfo)) == ZOK) {
        // 有子节点
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSMutableArray *array = [NSMutableArray array];
        node[@"children"] = array;
        if (depth != 0) {
            for (int i = 0; i < nodeInfo.path.count; i++) {
                NSString *str = nil;
                if (strcmp(path, "/") == 0) {
                    str = [[NSString stringWithFormat:@"%s/%@", path, nodeInfo.path[i]] substringFromIndex:1];
                } else {
                    str = [[NSString stringWithFormat:@"%s/%@", path, nodeInfo.path[i]] substringFromIndex:0];
                }
                [array addObject:[self getChildrenOfZk:zh path:str.cString depth:depth - 1]];
            }
        }
    } else {
        
    }
    return node;
}

- (NSMutableDictionary *) nodeForIndexPath:(NSIndexPath *) indexPath {
    NSMutableDictionary *node = self.treeNodes[0];
    NSMutableString *path = [NSMutableString string];
    for (int i = 1; i < [indexPath length]; i++) {
        NSUInteger index = [((NSIndexPath *)indexPath) indexAtPosition:i];
        node = ((NSMutableArray *)[node valueForKey:@"children"])[index];
        [path insertString:@"/" atIndex:path.length];
        [path insertString:[node valueForKey:@"name"] atIndex:path.length];
    }
    return node;
}

- (void) refreshStat:(const struct Stat *)stat {
//    [thisClass setCurrentNodeValue:[[NSString alloc] initWithUTF8String:value]];
    [thisClass setCurrentCzxid:[NSString stringWithFormat:@"%lld", stat->czxid]];
    [thisClass setCurrentMzxid:[NSString stringWithFormat:@"%lld", stat->mzxid]];
    [thisClass setCurrentCtime:[NSString stringWithFormat:@"%lld", stat->ctime]];
    [thisClass setCurrentMtime:[NSString stringWithFormat:@"%lld", stat->mtime]];
    [thisClass setCurrentVersion:[NSString stringWithFormat:@"%d", stat->version]];
    [thisClass setCurrentAVersion:[NSString stringWithFormat:@"%d", stat->aversion]];
    [thisClass setCurrentCVersion:[NSString stringWithFormat:@"%d", stat->cversion]];
    [thisClass setCurrentephemeralOwner:[NSString stringWithFormat:@"%lld", stat->ephemeralOwner]];
    [thisClass setCurrentDataLength:[NSString stringWithFormat:@"%d", stat->dataLength]];
    [thisClass setCurrentNumChildren:[NSString stringWithFormat:@"%d", stat->numChildren]];
    [thisClass setCurrentPzxid:[NSString stringWithFormat:@"%lld", stat->pzxid]];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSStoryboardSegueIdentifier)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"addZkNode"] && currentNode != nil) {
        return YES;
    }
    return NO;
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addZkNode"]) {
        ZkAddNodeViewController *controller = (ZkAddNodeViewController *)((NSWindowController *)segue.destinationController).contentViewController;
        [controller setNodePath:currentNode[@"path"]];
        [controller setDelegate:self];
        [controller setWindowController:segue.destinationController];
    }
}

- (void)onNodeAdd:(NSString *)nodeName value:(NSString *)nodeValue {
    ZkStringCompletitionInfo *info = [[ZkStringCompletitionInfo alloc]initWithSema:dispatch_semaphore_create(0)];
    zoo_acreate(zhandle, [[NSString stringWithFormat:@"%@/%@", currentNode[@"path"], nodeName] UTF8String], [nodeValue UTF8String], (int)nodeValue.length, &ZOO_OPEN_ACL_UNSAFE, ZOO_PERSISTENT, string_completition, (__bridge const void *)(info));
    dispatch_semaphore_wait(info.sema, DISPATCH_TIME_FOREVER);
}

- (NSIndexPath *)findNodeByPath:(const char *) path {
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:0];
    if (strcmp(path, "/") == 0) {
        return indexPath;
    }
    NSString *pathStr = [NSString stringWithFormat:@"%s", path];
    NSArray<__kindof NSString *> *pathComponents = [pathStr componentsSeparatedByString:@"/"];
    
    NSMutableDictionary *node = self.treeNodes[0];
    for (int i = 1; i < pathComponents.count; i++) {
        NSLog(@"%@", pathComponents[i]);
        NSMutableArray<__kindof NSMutableDictionary *> *children = node[@"children"];
        if (children == nil || children.count == 0) {
            return nil;
        }
        bool find = false;
        for (int j = 0; j < children.count; j++) {
            if ([children[j][@"name"] isEqualToString:pathComponents[i]]) {
                find = true;
                node = children[j];
                indexPath = [indexPath indexPathByAddingIndex:j];
                break;
            }
        }
        if (!find) {
            return nil;
        }
    }
    NSLog(@"%@", indexPath);
    return indexPath;
}

- (void) showLoading:(BOOL) loading {
    if (loading) {
        [self.maskView setHidden:NO];
        [self setLoading:YES];
    } else {
        [self.maskView setHidden:YES];
        [self setLoading:NO];
    }
}

@end
