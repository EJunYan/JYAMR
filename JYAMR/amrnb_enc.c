//
//  armnb_enc.c
//  JYAMR
//
//  Created by LongJunYan on 2018/4/11.
//  Copyright © 2018年 onelcat. All rights reserved.
//

#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#include "interf_enc.h"
#include "amrnb_enc.h"
#include "wavreader.h"



/**
 wav -> amr
 wav 格式说明:
 - SampleRate: 8000 采样率
 - LinearPCMBitDepth: 16 采样位数
 - NumberOfChannels: 1  声道
 @param wavFile 文件路径
 @param amrFile 文件路径
 @return return
 */
enum amrnb_error amrnb_enc(const char *wavFile, const char *amrFile) {
    enum Mode mode = MR122;
    int dtx = 0;
    const char *infile, *outfile;
    FILE *out;
    void *wav, *amr;
//    int ret = amrnb_enc_ok;
    int format, sampleRate, channels, bitsPerSample;
    int inputSize;
    uint8_t* inputBuf;
    
    infile = wavFile;
    outfile = amrFile;
    
    wav = wav_read_open(infile);

    if (!wav) {
//        printf("Unable to open wav file %s\n", infile);
        return unable_to_open_wav_file;
    }
    if (!wav_get_header(wav, &format, &channels, &sampleRate, &bitsPerSample, NULL)) {
//        printf("Bad wav file %s\n", infile);
        return bad_wav_file;
    }
    if (format != 1) {
//        printf("Unsupported WAV format %d\n", format);
        return 1;
    }
    if (bitsPerSample != 16) {
//        printf("Unsupported WAV sample depth %d\n", bitsPerSample);
        return unsupported_wav_format;
    }
    if (channels != 1) {
//        printf("Warning, only compressing one audio channel\n");
        return only_compressing_one_audio_channel;
    }
    
    if (sampleRate != 8000) {
//        printf("Warning, AMR-NB uses 8000 Hz sample rate (WAV file has %d Hz)\n", sampleRate);
        return uses_8000_hz_sample_rate;
    }
    
    inputSize = channels*2*160;
    inputBuf = (uint8_t*) malloc(inputSize);
    
    amr = Encoder_Interface_init(dtx);
    out = fopen(outfile, "wb");
    if (!out) {
//        perror(outfile);
        return unable_to_open_amr_file;
    }
    
    fwrite("#!AMR\n", 1, 6, out);
    while (1) {
        short buf[160];
        uint8_t outbuf[500];
        int read, i, n;
        read = wav_read_data(wav, inputBuf, inputSize);
        read /= channels;
        read /= 2;
        if (read < 160)
            break;
        for (i = 0; i < 160; i++) {
            const uint8_t* in = &inputBuf[2*channels*i];
            buf[i] = in[0] | (in[1] << 8);
        }
        n = Encoder_Interface_Encode(amr, mode, buf, outbuf, 0);
        fwrite(outbuf, 1, n, out);
    }
    free(inputBuf);
    fclose(out);
    Encoder_Interface_exit(amr);
    wav_read_close(wav);
    return amrnb_ok;
}

