//
//  XINJPEGTool.h
//  LivePhotoMake
//
//  Created by valiant on 2018/12/27.
//  Copyright © 2018 xin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XINJPEGTool : NSObject

- (id)initWithPath:(NSString *)path;

- (void)XIN_writeDest:(NSString *)dest assetIdentifier:(NSString *)assetIdentifier result:(void(^)(BOOL res))result;

@end
