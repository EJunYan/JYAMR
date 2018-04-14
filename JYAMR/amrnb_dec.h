//
//  amrnb_dec.h
//  JYAMR
//
//  Created by LongJunYan on 2018/4/11.
//  Copyright © 2018年 onelcat. All rights reserved.
//


#ifndef amrnb_dec_h
#define amrnb_dec_h

#include <stdio.h>

#include "amrnb_enc.h"

extern enum amrnb_error amrnb_dec(const char *amrFile, const char *wavFile);

#endif /* amrnb_dec_h */
