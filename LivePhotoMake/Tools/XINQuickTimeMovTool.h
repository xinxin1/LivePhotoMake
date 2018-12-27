//
//  XINQuickTimeMovTool.h
//  LivePhotoMake
//
//  Created by valiant on 2018/12/27.
//  Copyright © 2018 xin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XINQuickTimeMovTool : NSObject
- (id)initWithPath:(NSString *)path;

- (void)XIN_write:(NSString *)dest assetIdentifier:(NSString *)assetIdentifier result:(void(^)(BOOL res))result;
@end
