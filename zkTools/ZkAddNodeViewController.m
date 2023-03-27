//
//  ZkAddNodeViewController.m
//  zkTools
//
//  Created by Nimitz_007 on 2023/3/22.
//  Copyright © 2023 Nimitz. All rights reserved.
//

#import "ZkAddNodeViewController.h"

@interface ZkAddNodeViewController ()

@end

@implementation ZkAddNodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
- (IBAction)onConfirm:(id)sender {
    NSAlert *alert;
    if (self.nodeName.length == 0) {
        alert = [[NSAlert alloc] init];
        [alert setMessageText:@"请输入节点名称"];
        [alert setAlertStyle:NSAlertStyleCritical];
    }
    if (alert != nil) {
        [alert runModal];
    } else {
        [self.delegate onNodeAdd:self.nodeName value:self.nodeValue];
        [self.windowController close];
    }
}

- (IBAction)onCancel:(id)sender {
//    [self dismissViewController:self];
    [self.windowController close];
}

@end
