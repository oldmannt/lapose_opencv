//
//  mat_transform.m
//  opencv_camera
//
//  Created by dyno on 7/18/16.
//  Copyright © 2016 dyno. All rights reserved.
//

#import "video_writer_bridge.h"

#include <string>
#include "video_writer.hpp"

@implementation VideoWriterObj

+ (VideoWriterObj* _Nonnull)create{
    return [[VideoWriterObj alloc] init];
}

- (BOOL)iniliaze:(const NSString* _Nonnull)file{
    std::string cstr_file = {[file UTF8String], [file lengthOfBytesUsingEncoding:NSUTF8StringEncoding]};
    return VideoWriterTest::instance().initialize(cstr_file, 20);
}

- (void)writerFrame:(CMSampleBufferRef _Nonnull)buffer{
    
    CVImageBufferRef ibrImageBuffer = CMSampleBufferGetImageBuffer(buffer);
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(ibrImageBuffer, 0);
    // Acquisition of base address.
    uint8_t* baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(ibrImageBuffer, 0);
    //    _sztBytesPerRow = CVPixelBufferGetBytesPerRow(_ibrImageBuffer);
    // Get the size.
    size_t sztWidth = CVPixelBufferGetWidth(ibrImageBuffer);
    size_t sztHeight = CVPixelBufferGetHeight(ibrImageBuffer);

    cv::Mat matEdge((int)sztHeight, (int)sztWidth, CV_8UC4, (void*)baseAddress);
    CVPixelBufferUnlockBaseAddress(ibrImageBuffer, 0);
    
    VideoWriterTest::instance().writerFrame((int64_t)&matEdge);
}

- (void)releaseObj{
    VideoWriterTest::instance().release();
}

@end
