//
//  XINLivePhotoMakeTool.h
//  LivePhotoMake
//
//  Created by valiant on 2018/12/27.
//  Copyright © 2018 xin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XINLivePhotoMakeTool : NSObject
/**
 * Live Photo 制作方法调用
 * imagePath    : Live Photo静态时展示的图片路径
 * videoPath    : 制作Live Photo的视频路径
 * toImagePath  : 处理后的图片存储路径
 * toVideoPath  : 处理后的视频存储路径
 * tmpImagePath : 临时处理的图片存储路径
 * SuccessHandler   : Block返回存储结果
 */
- (void)XIN_LivePhotoMakeWithImagePath:(NSString * _Nonnull)imagePath VideoPath:(NSString * _Nonnull)videoPath toImagePath:(NSString *)toImagePath toVideoPath:(NSString *)toVideoPath tmpImagePath:(NSString *)tmpImagePath Success:(void(^)(BOOL Successed))SuccessHandler;

@end

NS_ASSUME_NONNULL_END
