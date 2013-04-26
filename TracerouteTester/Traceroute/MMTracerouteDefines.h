//
//  MMTracerouteDefines.h
//  PingTester
//
//  Created by Bruno Bulić on 3/6/13.
//
//

#ifndef PingTester_MMTracerouteDefines_h
#define PingTester_MMTracerouteDefines_h

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#import <AssertMacros.h>

struct IPHeader {
    uint8_t     versionAndHeaderLength;
    uint8_t     differentiatedServices;
    uint16_t    totalLength;
    uint16_t    identification;
    uint16_t    flagsAndFragmentOffset;
    uint8_t     timeToLive;
    uint8_t     protocol;
    uint16_t    headerChecksum;
    uint8_t     sourceAddress[4];
    uint8_t     destinationAddress[4];
    // options...
    // data...
};
typedef struct IPHeader IPHeader;

char * readableAddressFromCharArray(const uint8_t * address);
char * sourceAddress(const IPHeader *);
char * destAddress(const IPHeader *);

check_compile_time(sizeof(IPHeader) == 20);
check_compile_time(offsetof(IPHeader, versionAndHeaderLength) == 0);
check_compile_time(offsetof(IPHeader, differentiatedServices) == 1);
check_compile_time(offsetof(IPHeader, totalLength) == 2);
check_compile_time(offsetof(IPHeader, identification) == 4);
check_compile_time(offsetof(IPHeader, flagsAndFragmentOffset) == 6);
check_compile_time(offsetof(IPHeader, timeToLive) == 8);
check_compile_time(offsetof(IPHeader, protocol) == 9);
check_compile_time(offsetof(IPHeader, headerChecksum) == 10);
check_compile_time(offsetof(IPHeader, sourceAddress) == 12);
check_compile_time(offsetof(IPHeader, destinationAddress) == 16);


// ICMP type and code combinations:
enum {
    kICMPTypeEchoReply   = 0,               // code is always 0
    kICMPTypeDestinationUnreachable = 3,
    kICMPTypeEchoRequest = 8,               // code is always 0
    kICMPTypeTimeExceeded = 11,
};

enum {
    kICMPCodeTimeExceededTTLExpired                 = 0,
    kICMPCodeTimeExceededFragmentReassemblyExceeded = 1
};

enum {
    kICMPCodeDefault = 0,
    kICMPCodeFragmentTimeExceeded = 1,
};

// API Wrapper
typedef enum {
    kICMPPingValid = kICMPTypeEchoReply,
    kICMPTimeExceeded = kICMPTypeTimeExceeded,
    kICMPDestinationUnreachable = kICMPTypeDestinationUnreachable,
    kICMPPacketNotFound = -666,
    kICMPInvalid = INT_MIN,
} ResponsePacketStatus;

// ICMP header structure:
struct ICMPHeader {
    uint8_t     type;
    uint8_t     code;
    uint16_t    checksum;
    uint16_t    identifier;
    uint16_t    sequenceNumber;
    // data...
};
typedef struct ICMPHeader ICMPHeader;

char * formatHeader(ICMPHeader * header);

check_compile_time(sizeof(ICMPHeader) == 8);
check_compile_time(offsetof(ICMPHeader, type) == 0);
check_compile_time(offsetof(ICMPHeader, code) == 1);
check_compile_time(offsetof(ICMPHeader, checksum) == 2);
check_compile_time(offsetof(ICMPHeader, identifier) == 4);
check_compile_time(offsetof(ICMPHeader, sequenceNumber) == 6);

#endif
