//
//  mat_transform.h
//  opencv_camera
//
//  Created by dyno on 7/18/16.
//  Copyright © 2016 dyno. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoWriterObj : NSObject
+ (VideoWriterObj* _Nonnull)create;
- (BOOL)iniliaze:(const NSString* _Nonnull)file;
- (void)writerFrame:(CMSampleBufferRef _Nonnull)buffer;
- (void)releaseObj;

@end