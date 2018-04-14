//
//  JYAMRPlayAudio.swift
//  JYAMR
//
//  Created by LongJunYan on 2018/4/12.
//  Copyright © 2018年 onelcat. All rights reserved.
//

import Foundation
import AVFoundation

public class JYAMRPlayAudio: NSObject {
    
    private var decoder: JYAMRNB
    private var amrPath: JYAMRPath
    private var player: AVAudioPlayer?
    
    private var isPlaying = false
    
    /// 是否开启红外 默认开启
    public var isProximityMonitoring: Bool = true
    
    override public init() {
        decoder = JYAMRNB()
        amrPath = JYAMRPath()
        
        super.init()
        
        if isProximityMonitoring {
            NotificationCenter.default.addObserver(self, selector: #selector(self.proximityStateDidChange(noti:)), name: NSNotification.Name.UIDeviceProximityStateDidChange, object: nil)
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
            debugPrint("配置错误")
        }
        
    }
    
    
    public func paly(amrPath: URL) -> Bool{
        self.amrPath.deleteWAV()
        
        
        guard let wavPath = self.amrPath.wav else {
            return false
        }
        
        // 停止其他语音
        
        do {
            try decoder.decoder(amrPath: amrPath, wavPath: wavPath)
            let wavData = try Data(contentsOf: wavPath)
            player = try AVAudioPlayer(data: wavData)
            
            player?.isMeteringEnabled = true
            player?.delegate = self
            player?.volume = 1.0
            player?.numberOfLoops = 0
            
            UIDevice.current.isProximityMonitoringEnabled = isProximityMonitoring
            
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.none)
            } catch _ {
                
            }
            
            guard let player = self.player else {
                return false
            }
            
            if player.prepareToPlay() {
                player.play()
                
                if player.isPlaying {
                    isPlaying = true
                } else {
                    isPlaying = false
                    return false
                }
                
            }
        } catch let error {
            debugPrint("音频解码错误",error.localizedDescription)
        }
        
        return true
    }
    
    public func stop() {
        guard let player = self.player else {
            return
        }
        
        if player.isPlaying {
            player.stop()
            self.player = nil
            isPlaying = false
        }
        
        UIDevice.current.isProximityMonitoringEnabled = false
    }
    
    @objc func proximityStateDidChange(noti: Notification) {
        
        do {
            if UIDevice.current.proximityState {
                // 靠近听筒
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
                
            } else {
                // 远离听筒
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            }
        } catch let error {
            debugPrint("红外传感器错误", error.localizedDescription)
        }
        

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceProximityStateDidChange, object: nil)
        UIDevice.current.isProximityMonitoringEnabled = false
    }
}

extension JYAMRPlayAudio: AVAudioPlayerDelegate {
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            self.stop()
        }
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    }
    

    
}
