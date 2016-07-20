//
//  video_writer.hpp
//  opencv_camera
//
//  Created by dyno on 7/18/16.
//  Copyright © 2016 dyno. All rights reserved.
//

#ifndef video_writer_hpp
#define video_writer_hpp

#include <string>
#include <opencv2/videoio/videoio.hpp>

class VideoWriterTest {
public:
    static VideoWriterTest& instance();
    
    bool initialize(const std::string& file, int fps);
    void writerFrame(int64_t frame_ptr);
    void release();
    
private:
    bool _initialize(const std::string &file, int fps, int width, int height);
    
    std::string m_file;
    int m_fps;
    cv::VideoWriter m_writer;
};

#endif /* video_writer_hpp */
