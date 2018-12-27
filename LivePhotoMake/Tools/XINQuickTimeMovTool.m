//
//  XINQuickTimeMovTool.m
//  LivePhotoMake
//
//  Created by valiant on 2018/12/27.
//  Copyright © 2018 xin. All rights reserved.
//

#import "XINQuickTimeMovTool.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const XIN_ContentIdentifierKey = @"com.apple.quicktime.content.identifier";
static NSString *const XIN_StillImageTimeKey = @"com.apple.quicktime.still-image-time";
static NSString *const XIN_SpaceQuickTimeMetadataKey = @"mdta";

static NSString *const XIN_FirstCustomKey  = @"XIN_first";
static NSString *const XIN_SecondCustomKey = @"XIN_second";

@interface XINQuickTimeMovTool ()
@property(nonatomic, copy)NSString *XIN_path;
@property(nonatomic, assign)CMTimeRange XIN_dummyTimeRange;
@property(nonatomic, strong)AVURLAsset *XIN_asset;
@end

@implementation XINQuickTimeMovTool
- (id)initWithPath:(NSString *)path {
    if (self = [super init]) {
        self.XIN_path = path;
    }
    return self;
}

- (CMTimeRange)XIN_dummyTimeRange {
    return CMTimeRangeMake(CMTimeMake(0, 1000), CMTimeMake(200, 3000));
}

- (AVURLAsset *)XIN_asset {
    if (!_XIN_asset) {
        NSURL *url = [NSURL fileURLWithPath:self.XIN_path];
        _XIN_asset = [AVURLAsset assetWithURL:url];
    }
    return _XIN_asset;
}

- (NSString *)XIN_readAssetIdentifier {
    for (AVMetadataItem *item in [self XIN_metadata]) {
        if ((NSString *)(item.key) == XIN_ContentIdentifierKey &&
            item.keySpace == XIN_SpaceQuickTimeMetadataKey) {
            return [NSString stringWithFormat:@"%@",item.value];
        }
    }
    return nil;
}

- (NSNumber *)XIN_readStillImageTime {
    AVAssetTrack *track = [self XIN_track:AVMediaTypeMetadata];
    if (track) {
        NSDictionary *dict = [self XIN_reader:track settings:nil];
        AVAssetReader *reader = [dict objectForKey:XIN_FirstCustomKey];
        [reader startReading];
        AVAssetReaderOutput *output = [dict objectForKey:XIN_SecondCustomKey];
        while (YES) {
            CMSampleBufferRef buffer = [output copyNextSampleBuffer];
            if (!buffer) {
                return nil;
            }
            if (CMSampleBufferGetNumSamples(buffer) != 0) {
                AVTimedMetadataGroup *group = [[AVTimedMetadataGroup alloc] initWithSampleBuffer:buffer];
                for (AVMetadataItem *item in group.items) {
                    if ((NSString *)(item.key) == XIN_StillImageTimeKey &&
                        item.keySpace == XIN_SpaceQuickTimeMetadataKey) {
                        return item.numberValue;
                    }
                }
            }
        }
    }
    return nil;
}

- (void)XIN_write:(NSString *)dest assetIdentifier:(NSString *)assetIdentifier result:(void(^)(BOOL res))result {
    AVAssetReader *audioReader = nil;
    AVAssetWriterInput *audioWriterInput = nil;
    AVAssetReaderOutput *audioReaderOutput = nil;

    @try {
        // reader for source video
        AVAssetTrack *track = [self XIN_track:AVMediaTypeVideo];
        if (!track) {
            NSLog(@"not found video track");
            if (result) {
                result(NO);
            }
            return;
        }
        NSDictionary *dict = [self XIN_reader:track settings:@{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]}];
        AVAssetReader *reader = [dict objectForKey:XIN_FirstCustomKey];
        AVAssetReaderOutput *output = [dict objectForKey:XIN_SecondCustomKey];
        // writer for mov
        NSError *writerError = nil;
        AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:dest] fileType:AVFileTypeQuickTimeMovie error:&writerError];
        writer.metadata = @[[self XIN_metadataFor:assetIdentifier]];
        
        // video track
        AVAssetWriterInput *input = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:[self XIN_videoSettings:track.naturalSize]];
        input.expectsMediaDataInRealTime = YES;
        input.transform = track.preferredTransform;
        [writer addInput:input];
        
        NSURL *url = [NSURL fileURLWithPath:self.XIN_path];
        AVAsset *aAudioAsset = [AVAsset assetWithURL:url];
        
        if (aAudioAsset.tracks.count > 1) {
            NSLog(@"Has Audio");
            // setup audio writer
            audioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
            
            audioWriterInput.expectsMediaDataInRealTime = NO;
            if ([writer canAddInput:audioWriterInput]) {
                [writer addInput:audioWriterInput];
            }
            // setup audio reader
            AVAssetTrack *audioTrack = [aAudioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
            audioReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:nil];
            @try {
                NSError *audioReaderError = nil;
                audioReader = [AVAssetReader assetReaderWithAsset:aAudioAsset error:&audioReaderError];
                if (audioReaderError) {
                    NSLog(@"Unable to read Asset, error: %@",audioReaderError);
                }
            } @catch (NSException *exception) {
                NSLog(@"Unable to read Asset: %@", exception.description);
            } @finally {
                
            }
            
            if ([audioReader canAddOutput:audioReaderOutput]) {
                [audioReader addOutput:audioReaderOutput];
            } else {
                NSLog(@"cant add audio reader");
            }
        }
        
        // metadata track
        AVAssetWriterInputMetadataAdaptor *adapter = [self XIN_metadataAdapter];
        [writer addInput:adapter.assetWriterInput];
        
        // creating video
        [writer startWriting];
        [reader startReading];
        [writer startSessionAtSourceTime:kCMTimeZero];
        
        // write metadata track
        AVMetadataItem *metadataItem = [self XIN_metadataForStillImageTime];
        
        [adapter appendTimedMetadataGroup:[[AVTimedMetadataGroup alloc] initWithItems:@[metadataItem] timeRange:self.XIN_dummyTimeRange]];
        
        // write video track
        [input requestMediaDataWhenReadyOnQueue:dispatch_queue_create("assetVideoWriterQueue", 0) usingBlock:^{
            while (input.isReadyForMoreMediaData) {
                if (reader.status == AVAssetReaderStatusReading) {
                    CMSampleBufferRef buffer = [output copyNextSampleBuffer];
                    if (buffer) {
                        if (![input appendSampleBuffer:buffer]) {
                            NSLog(@"cannot write: %@", writer.error);
                            [reader cancelReading];
                        }
                        //释放内存，否则出现内存问题
                        CFRelease(buffer);
                    }
                } else {
                    [input markAsFinished];
                    if (reader.status == AVAssetReaderStatusCompleted && aAudioAsset.tracks.count > 1) {
                        [audioReader startReading];
                        [writer startSessionAtSourceTime:kCMTimeZero];
                        dispatch_queue_t media_queue = dispatch_queue_create("assetAudioWriterQueue", 0);
                        [audioWriterInput requestMediaDataWhenReadyOnQueue:media_queue usingBlock:^{
                            while ([audioWriterInput isReadyForMoreMediaData]) {
                                
                                CMSampleBufferRef sampleBuffer2 = [audioReaderOutput copyNextSampleBuffer];
                                if (audioReader.status == AVAssetReaderStatusReading && sampleBuffer2 != nil) {
                                    if (![audioWriterInput appendSampleBuffer:sampleBuffer2]) {
                                        [audioReader cancelReading];
                                    }
                                } else {
                                    [audioWriterInput markAsFinished];
                                    NSLog(@"Audio writer finish");
                                    [writer finishWritingWithCompletionHandler:^{
                                        NSError *e = writer.error;
                                        if (e) {
                                            NSLog(@"cannot write: %@",e);
                                        } else {
                                            NSLog(@"finish writing.");
                                        }
                                    }];
                                }
                                if (sampleBuffer2) {//释放内存，否则出现内存问题
                                    CFRelease(sampleBuffer2);
                                }
                            }
                        }];
                    } else {
                        NSLog(@"Video Reader not completed");
                        [writer finishWritingWithCompletionHandler:^{
                            NSError *e = writer.error;
                            if (e) {
                                NSLog(@"cannot write: %@",e);
                            } else {
                                NSLog(@"finish writing.");
                            }
                        }];
                    }
                }
            }
        }];
        while (writer.status == AVAssetWriterStatusWriting) {
           @autoreleasepool {
               [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
           }
        }
        if (writer.error) {
            if (result) {
                result(NO);
            }
            NSLog(@"cannot write: %@", writer.error);
        } else {
            if (result) {
                result(YES);
            }
            NSLog(@"write finish");
        }
    } @catch (NSException *exception) {
        if (result) {
            result(NO);
        }
        NSLog(@"error: %@", exception.description);
    } @finally {
        
    }

}

- (NSArray<AVMetadataItem*> *)XIN_metadata {
    return [self.XIN_asset metadataForFormat:AVMetadataFormatQuickTimeMetadata];
}

- (AVAssetTrack *)XIN_track:(NSString *)mediType {
    return [self.XIN_asset tracksWithMediaType:mediType].firstObject;
}

- (NSDictionary *)XIN_reader:(AVAssetTrack *)track settings:(NSDictionary *)settings {
    AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:settings];
    NSError *readerError = nil;
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:self.XIN_asset error:&readerError];
    [reader addOutput:output];
    return @{XIN_FirstCustomKey:reader, XIN_SecondCustomKey:output};
}

- (AVAssetWriterInputMetadataAdaptor *)XIN_metadataAdapter {
    NSDictionary *spec = @{
                           (__bridge NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier:[NSString stringWithFormat:@"%@/%@",XIN_SpaceQuickTimeMetadataKey,XIN_StillImageTimeKey],
                           (__bridge NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType:@"com.apple.metadata.datatype.int8"
                           };
    
    CMFormatDescriptionRef desc = nil;
    
    CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, (__bridge CFArrayRef)@[spec], &desc);
    AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata outputSettings:nil sourceFormatHint:desc];
    return [AVAssetWriterInputMetadataAdaptor assetWriterInputMetadataAdaptorWithAssetWriterInput:input];
}

- (NSDictionary *)XIN_videoSettings:(CGSize)size {
    return @{
             AVVideoCodecKey : AVVideoCodecTypeH264,
             AVVideoWidthKey : @(size.width),
             AVVideoHeightKey : @(size.height)
             };
}

- (AVMetadataItem *)XIN_metadataFor:(NSString *)assetIdentifier {
    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.key = XIN_ContentIdentifierKey;
    item.keySpace = XIN_SpaceQuickTimeMetadataKey;
    item.value = assetIdentifier;
    item.dataType = @"com.apple.metadata.datatype.UTF-8";
    return item;
}

- (AVMetadataItem *)XIN_metadataForStillImageTime {
    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.key = XIN_StillImageTimeKey;
    item.keySpace = XIN_SpaceQuickTimeMetadataKey;
    item.value = @(0);
    item.dataType = @"com.apple.metadata.datatype.int8";
    return item;
}

@end
