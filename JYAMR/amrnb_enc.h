//
//  amrnb_enc.h
//  JYAMR
//
//  Created by LongJunYan on 2018/4/11.
//  Copyright © 2018年 onelcat. All rights reserved.
//

enum amrnb_error {
    amrnb_ok = 0,
    unable_to_open_wav_file,
    bad_wav_file,
    unsupported_wav_format,
    only_compressing_one_audio_channel,
    uses_8000_hz_sample_rate,
    unable_to_open_amr_file,
    bad_amr_header,
};

#ifndef armnb_enc_h
#define armnb_enc_h

#include <stdio.h>

extern enum amrnb_error amrnb_enc(const char *wavFile, const char *amrFile);

#endif /* armnb_enc_h */
