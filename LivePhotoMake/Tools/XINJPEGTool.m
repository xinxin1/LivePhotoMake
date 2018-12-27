//
//  XINJPEGTool.m
//  LivePhotoMake
//
//  Created by valiant on 2018/12/27.
//  Copyright © 2018 xin. All rights reserved.
//

#import "XINJPEGTool.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
static NSString * const XIN_AppleMakeLiveKey_AssetIdentifier = @"17";

@interface XINJPEGTool ()
@property(nonatomic,copy) NSString *XIN_path;

@end

@implementation XINJPEGTool

- (id)initWithPath:(NSString *)path {
    if (self = [super init]) {
        self.XIN_path = path;
    }
    return self;
}

- (NSString *)XIN_read {
    NSDictionary *met = [self XIN_metadata];
    if (!met) {
        return nil;
    }
    NSDictionary *dict = [met objectForKey:(__bridge NSString *)kCGImagePropertyMakerAppleDictionary];
    NSString *str = [dict objectForKey:XIN_AppleMakeLiveKey_AssetIdentifier];
    return str;
}

- (void)XIN_writeDest:(NSString *)dest assetIdentifier:(NSString *)assetIdentifier result:(void(^)(BOOL res))result {
    CGImageDestinationRef ref = CGImageDestinationCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:dest], kUTTypeJPEG, 1, nil);
    if (!ref) {
        if (result) {
            result(NO);
        }
        return;
    }
    CGImageSourceRef imageSource = [self XIN_imageSource];
    if (!imageSource) {
        if (result) {
            result(NO);
        }
        return;
    }
    NSMutableDictionary * metadata = [[self XIN_metadata] mutableCopy];
    if (!metadata) {
        if (result) {
            result(NO);
        }
        return;
    }
    //存储image
    NSMutableDictionary * makerNote = [[NSMutableDictionary alloc] init];
    [makerNote setObject:assetIdentifier forKey:XIN_AppleMakeLiveKey_AssetIdentifier];
    [metadata setObject:makerNote forKey:(__bridge NSString *)kCGImagePropertyMakerAppleDictionary];
    //存储图片 设置一些属性
    CGImageDestinationAddImageFromSource(ref, imageSource, 0, (__bridge CFDictionaryRef)metadata);
    CFRelease(imageSource);
    CGImageDestinationFinalize(ref);
    if (result) {
        result(YES);
    }
}

- (NSDictionary *)XIN_metadata {
    CGImageSourceRef ref = [self XIN_imageSource];
    NSDictionary * dict = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(ref, 0, nil));
    CFRelease(ref);
    return dict;
}

- (CGImageSourceRef)XIN_imageSource {
    return CGImageSourceCreateWithData((__bridge CFDataRef)[self XIN_data], nil);
}

- (NSData *)XIN_data {
    return [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:self.XIN_path]];
}

@end
