//
//  ViewController.m
//  LivePhotoMake
//
//  Created by valiant on 2018/12/27.
//  Copyright © 2018 xin. All rights reserved.
//

#import "ViewController.h"
#import "XINLivePhotoMakeTool.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self XIN_createView];
}


#pragma mark - View
- (void)XIN_createView {
    UIButton *XIN_button = [UIButton buttonWithType:UIButtonTypeCustom];
    XIN_button.frame = CGRectMake(20, 100, 200, 30);
    [XIN_button setTitle:@"Live Photo Make" forState:UIControlStateNormal];
    [XIN_button setBackgroundColor:[UIColor cyanColor]];
    [XIN_button addTarget:self action:@selector(XIN_LivePhotoMakeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:XIN_button];
}


#pragma mark - Action
- (void)XIN_LivePhotoMakeAction {
    // test 1 -------
//    NSString *fromImagePath = [[NSBundle mainBundle] pathForResource:@"1234" ofType:@"jpeg"];
//    NSString *fromVideoPath = [[NSBundle mainBundle] pathForResource:@"TQ3" ofType:@"mov"];
//    NSString *tmpImagePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"tmp/%@.jpg",[[fromImagePath lastPathComponent] stringByDeletingPathExtension]]];
//    NSString *toImagePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.jpg",[[fromImagePath lastPathComponent] stringByDeletingPathExtension]]];
//    NSString *toVideoPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.mov",[[fromVideoPath lastPathComponent] stringByDeletingPathExtension]]];
//    NSLog(@"开始制作与保存。。。");
//    [[XINLivePhotoMakeTool new] XIN_LivePhotoMakeWithImagePath:fromImagePath VideoPath:fromVideoPath toImagePath:toImagePath toVideoPath:toVideoPath tmpImagePath:tmpImagePath Success:^(BOOL Successed) {
//        NSLog(@"保存结果。。。。%d",Successed);
//    }];
    // test 2 -------
    NSString *fromImagePath = [[NSBundle mainBundle] pathForResource:@"d87" ofType:@"jpeg"];
//    NSString *fromImagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"d09.png"];
    NSString *fromVideoPath = [[NSBundle mainBundle] pathForResource:@"c81" ofType:@"mp4"];
    NSLog(@"开始制作与保存。。。");
    [[XINLivePhotoMakeTool new] XIN_LivePhotoMakeWithImagePath:fromImagePath VideoPath:fromVideoPath toImagePath:nil toVideoPath:nil tmpImagePath:nil Success:^(BOOL Successed) {
        NSLog(@"保存结果。。。。%d",Successed);
    }];
}

@end
