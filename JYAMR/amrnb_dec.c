//
//  amrnb_dec.c
//  JYAMR
//
//  Created by LongJunYan on 2018/4/11.
//  Copyright © 2018年 onelcat. All rights reserved.
//

#include <stdint.h>
#include <string.h>

#include "interf_dec.h"
#include "wavwriter.h"
#include "amrnb_dec.h"

/* From WmfDecBytesPerFrame in dec_input_format_tab.cpp */
const int sizes[] = { 12, 13, 15, 17, 19, 20, 26, 31, 5, 6, 5, 5, 0, 0, 0, 0 };

/**
 amr -> wav
 wav 格式说明:
 - SampleRate: 8000 采样率
 - LinearPCMBitDepth: 16 采样位数
 - NumberOfChannels: 1  声道
 @param amrFile 文件路径
 @param wavFile 文件路径
 @return
 */
enum amrnb_error amrnb_dec(const char *amrFile, const char *wavFile) {
    FILE* in;
    char header[6];
    int n;
    void *wav, *amr;
    //    if (argc < 3) {
    //        fprintf(stderr, "%s in.amr out.wav\n", argv[0]);
    //        return 1;
    //    }
    
    in = fopen(amrFile, "rb");
    if (!in) {
        //        perror(argv[1]);
        return unable_to_open_amr_file;
    }
    n = fread(header, 1, 6, in);
    if (n != 6 || memcmp(header, "#!AMR\n", 6)) {
//        fprintf(stderr, "Bad header\n");
        return bad_amr_header;
    }
    
    wav = wav_write_open(wavFile, 8000, 16, 1);
    if (!wav) {
//        fprintf(stderr, "Unable to open %s\n", wavFile);
        return unable_to_open_wav_file;
    }
    
    amr = Decoder_Interface_init();
    while (1) {
        uint8_t buffer[500], littleendian[320], *ptr;
        int size, i;
        int16_t outbuffer[160];
        /* Read the mode byte */
        n = fread(buffer, 1, 1, in);
        if (n <= 0)
            break;
        /* Find the packet size */
        size = sizes[(buffer[0] >> 3) & 0x0f];
        n = fread(buffer + 1, 1, size, in);
        if (n != size)
            break;
        
        /* Decode the packet */
        Decoder_Interface_Decode(amr, buffer, outbuffer, 0);
        
        /* Convert to little endian and write to wav */
        ptr = littleendian;
        for (i = 0; i < 160; i++) {
            *ptr++ = (outbuffer[i] >> 0) & 0xff;
            *ptr++ = (outbuffer[i] >> 8) & 0xff;
        }
        wav_write_data(wav, littleendian, 320);
    }
    fclose(in);
    Decoder_Interface_exit(amr);
    wav_write_close(wav);
    return amrnb_ok;
}

