//
//  BBNetworkHeaders.h
//  TracerouteTester
//
//  Created by Bruno Bulić on 4/23/13.
//  Copyright (c) 2013 MarlinMobile. All rights reserved.
//

#ifndef TracerouteTester_BBNetworkHeaders_h
#define TracerouteTester_BBNetworkHeaders_h

#include <arpa/inet.h>

typedef struct _BBHostInfoValidity {
    struct sockaddr addr;
    int isValid;
} bb_hivalidity;

int bb_hostinfo_populate(struct sockaddr *, int, void *);

#define FAIL    NO
#define WIN     YES

#endif
