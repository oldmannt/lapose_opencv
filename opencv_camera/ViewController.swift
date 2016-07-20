//
//  ViewController.swift
//  opencv_camera
//
//  Created by dyno on 7/18/16.
//  Copyright © 2016 dyno. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var btn_save: UIButton!
    @IBOutlet weak var btn_record: UIButton!
    @IBOutlet weak var img_preview: UIImageView!
    
    let m_camere_controller = CameraController()
    var m_video_file = String()
    let m_video_player : AVPlayerViewController = AVPlayerViewController()
    var m_player:AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let file_manager = NSFileManager.defaultManager()
        m_video_file = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        m_video_file.appendContentsOf("/test.mp4")
        
        if file_manager.fileExistsAtPath(m_video_file){
            do{
                try file_manager.removeItemAtPath(m_video_file);
            } catch let error as NSError{
                // contents could not be loaded
                NSLog("remove error \(error)")
            }
        }

        m_camere_controller.initialize(m_video_file, view: img_preview, fps: 10)
        m_camere_controller.cameraQuality = .High
        m_camere_controller.savePhotoToLibrary = false
        m_camere_controller.flashMode = .No
        
        //video_player.view.frame = self.view.bounds
        //self.view.addSubview(video_player.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func record(sender: AnyObject) {
        m_camere_controller.record = true;
    }
    
    @IBAction func save(sender: AnyObject) {
        m_camere_controller.record = false;
    }
    
    @IBAction func play(sender: AnyObject) {
        //m_video_player.view.hidden = true
        //m_video_player.player?.play()
        self.presentViewController(m_video_player, animated: true, completion: {() -> Void in
            self.m_player = AVPlayer(URL: NSURL(fileURLWithPath: self.m_video_file))
            self.m_video_player.player = self.m_player
            self.m_video_player.player?.play()
        })
    }

    @IBAction func start(sender: AnyObject) {
        m_camere_controller.startCamera()
    }
    
    @IBAction func stop(sender: AnyObject) {
        m_camere_controller.stopCamera()
    }
}

