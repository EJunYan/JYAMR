//
//  JYAMRRecordAudio.swift
//  JYAMR
//
//  Created by LongJunYan on 2018/4/11.
//  Copyright © 2018年 onelcat. All rights reserved.
//

import Foundation
import AVFoundation


@objc public protocol JYAMRRecordAudioDelegate {
    /// 0.1s 调用一次
    @objc optional func peakPowerSoundRecorded(peakPower: Double)
    
    func audioData(_ data: Data?)
}

struct JYAMRPath {
    
    private lazy var root: URL? = {
        
        let manager = FileManager.default
        let document = manager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
        
        guard let folder = document?.appendingPathComponent("JYAMR", isDirectory: true) else {
            return nil
        }
        
        if !manager.fileExists(atPath: folder.path) {
            do {
                try manager.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                debugPrint("获取路径错误", error)
                return nil
            }
        }
        
        return folder
    }()
    
    lazy var amr: URL? = {
        return root?.appendingPathComponent("temp.amr", isDirectory: false)
    }()
    
    lazy var wav: URL? = {
        return root?.appendingPathComponent("temp.wav", isDirectory: false)
    }()
    
    mutating func initPath() {
        self.deleteAMR()
        self.deleteWAV()
    }
    
    mutating func deleteAMR() {
        let manager = FileManager.default
        if let amr = amr {
            if manager.fileExists(atPath: amr.path) {
                try? manager.removeItem(at: amr)
            }
        }
    }
    
    mutating func deleteWAV() {
        let manager = FileManager.default
        
        if let wav = wav {
            if manager.fileExists(atPath: wav.path) {
                try? manager.removeItem(at: wav)
            }
        }
    }
    
    
}


public class JYAMRRecordAudio: NSObject {
    
    public weak var delegat: JYAMRRecordAudioDelegate?
    
    private var recorder: AVAudioRecorder?
    
    private var volumeTimer: Timer?
    
//    private let session: AVAudioSession
    
    private var recordSetting: [String: NSNumber]
    
    private var amrPath: JYAMRPath
    
    private var encoder: JYAMRNB
    
    private let dispatchQueue: DispatchQueue
    
    static let shared = JYAMRRecordAudio()
    
    override public init() {
        
//        session = AVAudioSession.sharedInstance()
        
        dispatchQueue = DispatchQueue(label: "jyamr.enc", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
        
        recordSetting = [AVSampleRateKey: NSNumber(value: 8000),
                         AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),
                         AVLinearPCMBitDepthKey: NSNumber(value: 16),
                         AVNumberOfChannelsKey: NSNumber(value: 1),
                         AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.min.rawValue)
        ];
        
        amrPath = JYAMRPath()
        
        encoder = JYAMRNB()
        
//        do {
//            //设置录音类型
//            try session.setCategory(AVAudioSessionCategoryRecord)
//
//            try session.setActive(true)
//
//        } catch let error {
//            debugPrint("录音初始化错误", error.localizedDescription)
////            return nil
//        }
        super.init()
        
    }
    
    public func begin() -> Bool {
        
        
        
        guard let wavFile = amrPath.wav else {
            return false
        }
        
        
        amrPath.initPath()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
            return false
        }
        
        do {
            
            recorder = try AVAudioRecorder(url: wavFile, settings: recordSetting)
            recorder?.delegate = self
            if recorder != nil{
                // 开启仪表计数功能
                recorder?.isMeteringEnabled = true
                // 准备录音
                recorder?.prepareToRecord()
                // 开始录音
                recorder?.record()
                // 启动定时器，定时更新录音音量
                volumeTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.levelTimer), userInfo: nil, repeats: true)
            }
        } catch let error {
            debugPrint("录音出错",error.localizedDescription)
            return false
        }
        return true
    }
    
    /// 返回录音数据 data
    public func stop() -> Bool {
        
        /// 停止录音
        recorder?.stop()
        recorder = nil
        
        /// 停止定时器
        volumeTimer?.invalidate()
        volumeTimer = nil
        
        return true
    }
    
    public func getAudioTime(data: Data) -> Double? {
        do {
            let play = try AVAudioPlayer(data: data)
            return play.duration
        } catch let error {
            debugPrint("获取语音长度错误",error.localizedDescription)
        }
        return nil
    }
    
    @objc private func levelTimer() {
        
        guard let recorder = self.recorder, let delegat = self.delegat else {
            return
        }
        
        // 刷新音量数据
        recorder.updateMeters()
        //获取音量的平均值
        //        let averageV: Float = recorder!.averagePower(forChannel: 0)
        //获取音量最大值
        let maxV:Float = recorder.peakPower(forChannel: 0)
        let lowPassResult: Double = pow(Double(10), Double(0.05*maxV))

//        debugPrint(lowPassResult)
        
        self.delegat?.peakPowerSoundRecorded?(peakPower: lowPassResult)
        
        
//        delegat.peakPowerSoundRecorded?(peakPower: lowPassResult)
        // 音量
//        debugLog("当前录音大小", lowPassResult)
        // 添加录音动画
    }
    
}

extension JYAMRRecordAudio: AVAudioRecorderDelegate {
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        
        self.volumeTimer?.invalidate()
        self.volumeTimer = nil
        debugPrint("录音错误")
    }
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
//        debugPrint("录音完成")
        
        guard let amrFile = amrPath.amr, let wavFile = amrPath.wav else {
            return
        }
        
        guard let delegat = self.delegat else {
            return
        }
        
        dispatchQueue.async {
            do {
                let s = Date()
//                debugPrint("开始编码", s)
                try self.encoder.encoder(wavPath: wavFile, amrPath: amrFile)
//                debugPrint("结束编码 - 获取 data 数据", Date().timeIntervalSince(s))
                let data = try Data(contentsOf: amrFile)
                delegat.audioData(data)
            } catch let error {
                debugPrint("编码错误",error.localizedDescription)
                return
            }
        }
        
    }
    
}
