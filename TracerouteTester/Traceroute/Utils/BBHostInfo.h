//
//  MMHostName.h
//  TracerouteTester
//
//  Created by Bruno Bulić on 4/23/13.
//  Copyright (c) 2013 MarlinMobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "BBNetworkHeaders.h"

/*
typedef enum {
    MMHostResolveResultAddr = 1,
    MMHostResolveResultHostName = 9,
    MMHostResolveResultError = INT_MIN,
} MMHostResolveResult;

typedef void(^MMHostNameResolveCallback)(MMHostResolveResult result, id contextObject);
*/

// Build a host name from the address or vice versa. Depending on whatever you initialized first.
@interface BBHostInfo : NSObject

@property (nonatomic, readonly) NSString *hostName;
@property (nonatomic, readonly) NSString *hostAddress;

- (id)initWithHostNameOrNumber:(NSString *)hostName;
- (struct sockaddr *)validAddress;

- (bb_hivalidity)isIPAddressStringValid:(NSString *)address;

@end
