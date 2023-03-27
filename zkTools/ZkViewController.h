//
//  ViewController.h
//  zkTools
//
//  Created by Nimitz_007 on 2021/7/11.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZkViewController : NSViewController

@property (weak) IBOutlet NSTextField *urlTf;

@property (weak) IBOutlet NSTextFieldCell *urlTfCell;

@property (nonatomic, weak) NSButton *connectBtn;

@property (nonatomic, weak) NSTextField *urlTextField;
@property (weak) IBOutlet NSTableColumn *tableColumn;

@property(nonatomic,strong) NSMutableArray<__kindof NSDictionary *> *treeNodes;

@property(nonatomic, strong) NSMutableArray *selectionIndexPaths;

@property (nonatomic) BOOL notConnected;

@property (nonatomic, weak) NSString *currentNodeName;

@property (nonatomic, weak) NSString *currentNodeValue;

@property (nonatomic, weak) NSString *currentCzxid;

@property (nonatomic, weak) NSString *currentMzxid;

@property (nonatomic, weak) NSString *currentCtime;

@property (nonatomic, weak) NSString *currentMtime;

@property (nonatomic, weak) NSString *currentVersion;

@property (nonatomic, weak) NSString *currentCVersion;

@property (nonatomic, weak) NSString *currentAVersion;

@property (nonatomic, weak) NSString *currentephemeralOwner;

@property (nonatomic, weak) NSString *currentDataLength;

@property (nonatomic, weak) NSString *currentNumChildren;

@property (nonatomic, weak) NSString *currentPzxid;

@property (strong) IBOutlet NSTreeController *treeController;

@property (weak) IBOutlet NSView *maskView;

@property (nonatomic) BOOL loading;

@property (nonatomic, weak) NSString *searchValue;

@property (nonatomic, weak) NSString *logContent;

@end

