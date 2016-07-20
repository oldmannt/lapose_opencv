//
//  video_writer.cpp
//  opencv_camera
//
//  Created by dyno on 7/18/16.
//  Copyright © 2016 dyno. All rights reserved.
//

#include "video_writer.hpp"
#include <opencv2/videoio/videoio_c.h>
#include <opencv2/imgproc/imgproc.hpp>

VideoWriterTest& VideoWriterTest::instance(){
    static VideoWriterTest s;
    return s;
}

bool VideoWriterTest::initialize(const std::string &file, int fps){
    m_file = file;
    m_fps = fps;
    return true;
}

bool VideoWriterTest::_initialize(const std::string &file, int fps, int width, int height){
    if (!m_writer.open(file, CV_FOURCC('M','P','4','V'), fps, cv::Size(width,height))){
        return false;
    }
    
    return true;
}

void VideoWriterTest::writerFrame(int64_t frame_ptr){
   
    cv::Mat* pmat = (cv::Mat*)frame_ptr;
    if (nullptr==pmat){
        return;
    }
    //cv::resize(<#InputArray src#>, <#OutputArray dst#>, <#Size dsize#>)
    
    if (!m_writer.isOpened()){
        if (!_initialize(m_file, m_fps, pmat->cols, pmat->rows)){
            printf("VideoWriterTest _initialize failed");
            return;
        }
    }
    
    m_writer.write(*pmat);
}

void VideoWriterTest::release(){
    if (!m_writer.isOpened())
        return;
    
    m_writer.release();
}