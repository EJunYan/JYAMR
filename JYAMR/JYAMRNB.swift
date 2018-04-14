//
//  JYAMRNB.swift
//  JYAMR
//
//  Created by LongJunYan on 2018/4/11.
//  Copyright © 2018年 onelcat. All rights reserved.
//

import Foundation

enum JYAMRNBError: Error {
    case unableToOpenWAVFile(String)
    case badWAVFile(String)
    case unsupportedWAVFormat(String)
    case onlyCompressingOneAudioChannel(String)
    case uses8000HzSampleRate(String)
    case unableToOpenAMRFile(String)
    case badAMRHeader(String)
}


/// WAV 文件格式说明 8000Hz 采样率 16 采样位数 1 单声道
/*
 [AVSampleRateKey: NSNumber(value: 8000),//采样率
 AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),
 AVLinearPCMBitDepthKey: NSNumber(value: 16),
 AVNumberOfChannelsKey: NSNumber(value: 1),
 AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.min.rawValue)
 ];
 */


public struct JYAMRNB {
    
    public func encoder(wavPath: URL, amrPath: URL) throws {
        
        let infile = NSString(string: wavPath.path)
        let outFile = NSString(string: amrPath.path)
        
        let inp = infile.utf8String!
        let outp = outFile.utf8String!
        
        let res = amrnb_enc(inp, outp)
        switch res {
        case unable_to_open_wav_file:
            throw JYAMRNBError.unableToOpenWAVFile("Unable to open wav file \(wavPath.path)")
        case bad_wav_file:
            throw JYAMRNBError.badWAVFile("Bad wav file \(wavPath.path)")
        case unsupported_wav_format:
            throw JYAMRNBError.unsupportedWAVFormat("Unsupported WAV format")
        case only_compressing_one_audio_channel:
            throw JYAMRNBError.onlyCompressingOneAudioChannel("Warning, only compressing one audio channel")
        case uses_8000_hz_sample_rate:
            throw JYAMRNBError.uses8000HzSampleRate("Warning, AMR-NB uses 8000 Hz sample rate")
        case unable_to_open_amr_file:
            throw JYAMRNBError.unableToOpenAMRFile("Unable to open amr file \(amrPath.path)")
        case amrnb_ok:
            break
        default:
            break
        }
    }
    
    public func decoder(amrPath: URL, wavPath: URL) throws {
        let infile = NSString(string: amrPath.path)
        let outFile = NSString(string: wavPath.path)
        let inp = infile.utf8String!
        let outp = outFile.utf8String!
        let res = amrnb_dec(inp, outp)
        switch res {
        case unable_to_open_wav_file:
            throw JYAMRNBError.unableToOpenWAVFile("Unable to open wav file \(wavPath.path)")
        case unable_to_open_amr_file:
            throw JYAMRNBError.unableToOpenAMRFile("Unable to open amr file \(amrPath.path)")
        case bad_amr_header:
            throw JYAMRNBError.badAMRHeader("Bad AMR header")
        case amrnb_ok:
            break
        default:
            break
        }
    }
    
}
