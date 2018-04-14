//
//  ViewController.swift
//  RecordVoice
//
//  Created by LongJunYan on 2018/4/11.
//  Copyright © 2018年 onelcat. All rights reserved.
//

import UIKit
import JYAMR

class ViewController: UIViewController {

    var record: JYAMRRecordAudio?
    
    var play: JYAMRPlayAudio?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        record = JYAMRRecordAudio()
        record?.delegat = self
        play = JYAMRPlayAudio()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func sr(_ sender: Any) {
        record?.begin()
    }
    
    @IBAction func str(_ sender: Any) {
        record?.stop()
    }
    
    @IBAction func play(_ sender: Any) {
        let filePath:String = NSHomeDirectory() + "/Documents/amr.mar"
        let url = URL.init(fileURLWithPath: filePath)
        play?.paly(amrPath: url)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: JYAMRRecordAudioDelegate{
    
    func audioData(_ data: Data?) {
        let filePath:String = NSHomeDirectory() + "/Documents/amr.mar"
        do {
            
            let time = self.record?.getAudioTime(data: data!)
            debugPrint(data?.count, time)
            
            let url = URL.init(fileURLWithPath: filePath)
            try data?.write(to: url)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    
}

