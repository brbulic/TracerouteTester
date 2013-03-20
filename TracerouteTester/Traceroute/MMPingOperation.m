//
//  MMPingOperation.m
//  PingTester
//
//  Created by Bruno Bulić on 3/10/13.
//
//

#import "MMPingOperation.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>

@interface MMPingOperation ()

@property (nonatomic, strong) NSData * hostAddress;
@property (nonatomic, assign) NSInteger nextSequenceNumber;
@property (nonatomic, assign) NSInteger identifier;

@property (nonatomic, assign) CFHostRef     host;
@property (nonatomic, assign) CFSocketRef   currentWorkingSocket;

@property (nonatomic, strong) NSNumber * ttl;

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;

- (void)_didFailWithError:(NSError *)error;

// some things are actually C Functions
void SocketReadCallback(CFSocketRef, CFSocketCallBackType, CFDataRef, const void *, void *);

uint16_t in_cksum(const void *buffer, size_t bufferLen);

@end

@implementation MMPingOperation {

}

- (id)initWithHostAddress:(NSData *)hostAddress
{
    self = [super init];
    if (self) {
        self.hostAddress = hostAddress;
        self.nextSequenceNumber = 0;
        self.identifier = (uint16_t)arc4random();
        
    }
    return self;
}

- (id)initWithHostAddressString:(NSString *)hostAddress {
    @throw [NSException exceptionWithName:NSInvalidArchiveOperationException reason:nil userInfo:nil];
    
    // just to kill the reason
    return nil;
}

- (void)beginPingWithTtl:(NSNumber *)number {
    
    if(number != nil && number.integerValue > 0) {
        self.ttl = number;
    } else {
        self.ttl = nil;
    }
    
    [self startPing];
}

- (void)startPing {
    int                     err;
    int                     fileDescriptor;
    const struct sockaddr * addrPtr;
    
    assert(self.hostAddress != nil);
    
    // Open the socket.
    addrPtr = (const struct sockaddr *) [self.hostAddress bytes];
    
    fileDescriptor = -1;
    err = 0;
    switch (addrPtr->sa_family) {
        case AF_INET: {
            fileDescriptor = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
            if (fileDescriptor < 0) {
                err = errno;
            }
        } break;
        case AF_INET6:
            assert(NO);
            // let's not support IPv6
        default: {
            err = EPROTONOSUPPORT;
        } break;
    }
    
    if (err != 0) {
        [self _didFailWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
    } else { // create a socket
        CFSocketContext     context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        CFRunLoopSourceRef  rls;
        
        // Wrap it in a CFSocket and schedule it on the runloop.
        
        self.currentWorkingSocket = CFSocketCreateWithNative(NULL, fileDescriptor, kCFSocketReadCallBack, SocketReadCallback, &context);
        assert(self.currentWorkingSocket != NULL);
        
        // The socket will now take care of clean up our file descriptor.
        
        assert(CFSocketGetSocketFlags(self.currentWorkingSocket) & kCFSocketCloseOnInvalidate );
        fileDescriptor = -1;
        
        rls = CFSocketCreateRunLoopSource(NULL, self.currentWorkingSocket, 0);
        assert(rls != NULL);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
        
        CFRelease(rls);
    }

    assert(fileDescriptor == -1);
    
    [self sendPingWithData:nil];

}

- (void)sendPingWithData:(NSData *)data
// See comment in header.
{
    int             err;
    NSData *        payload;
    NSMutableData * packet;
    ICMPHeader *    icmpPtr;
    ssize_t         bytesSent;
    
    // Construct the ping packet.
    
    payload = data;
    if (payload == nil) {
        payload = [[NSString stringWithFormat:@"%28zd bottles of beer on the wall", (ssize_t) 99 - (size_t) (self.nextSequenceNumber % 100) ] dataUsingEncoding:NSASCIIStringEncoding];
        assert(payload != nil);
        
        assert([payload length] == 56);
    }
    
    packet = [NSMutableData dataWithLength:sizeof(*icmpPtr) + [payload length]];
    assert(packet != nil);
    
    icmpPtr = [packet mutableBytes];
    icmpPtr->type = kICMPTypeEchoRequest;
    icmpPtr->code = 0;
    icmpPtr->checksum = 0;
    icmpPtr->identifier     = OSSwapHostToBigInt16(self.identifier);
    icmpPtr->sequenceNumber = OSSwapHostToBigInt16(self.nextSequenceNumber);
    memcpy(&icmpPtr[1], [payload bytes], [payload length]);
    
    // The IP checksum returns a 16-bit number that's already in correct byte order
    // (due to wacky 1's complement maths), so we just put it into the packet as a
    // 16-bit unit.
    
    icmpPtr->checksum = in_cksum([packet bytes], [packet length]);
    
    // Send the packet.
    
    if (self.currentWorkingSocket == NULL) {
        bytesSent = -1;
        err = EBADF;
    } else {
        if(self.ttl) {
            int ttl = self.ttl.integerValue;
            setsockopt(CFSocketGetNative(self.currentWorkingSocket), IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl));
        }
        bytesSent = sendto(
                           CFSocketGetNative(self.currentWorkingSocket),
                           [packet bytes],
                           [packet length],
                           0,
                           (struct sockaddr *) [self.hostAddress bytes],
                           (socklen_t) [self.hostAddress length]
                           );
        
        self.startDate = [NSDate date];
        err = 0;
        if (bytesSent < 0) {
            err = errno;
        }
    }
    
    // Handle the results of the send.
    if ( (bytesSent > 0) && (((NSUInteger) bytesSent) == [packet length]) ) {
        
        // Complete success.  Tell the client.
        
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(pingOperation:didSendPacket:)] ) {
            [self.delegate pingOperation:self didSendPacket:[NSData dataWithData:packet]];
        }
    } else {
        NSError *   error;
        
        // Some sort of failure.  Tell the client.
        
        if (err == 0) {
            err = ENOBUFS;          // This is not a hugely descriptor error, alas.
        }
        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(pingOperation:errorSendingPacket:withError:)] ) {
            [self.delegate pingOperation:self errorSendingPacket:[NSData dataWithData:packet] withError:error];
        }
    }
    
    self.nextSequenceNumber += 1;
}

- (void)_readDataFromSocket:(CFSocketRef) socketRef {
    int                     err;
    struct sockaddr_storage addr;
    socklen_t               addrLen;
    ssize_t                 bytesRead;
    void *                  buffer;
    enum { kBufferSize = 65535 };
    
    // 65535 is the maximum IP packet size, which seems like a reasonable bound
    // here (plus it's what <x-man-page://8/ping> uses).
    
    buffer = malloc(kBufferSize);
    assert(buffer != NULL);
    
    // Actually read the data.
    
    addrLen = sizeof(addr);
    bytesRead = recvfrom(CFSocketGetNative(socketRef), buffer, kBufferSize, 0, (struct sockaddr *) &addr, &addrLen);
    err = 0;
    if (bytesRead < 0) {
        err = errno;
    }
    
    // Process the data we read.
    
    if (bytesRead > 0) {
        NSMutableData *     packet;
        
        packet = [NSMutableData dataWithBytes:buffer length:bytesRead];
        assert(packet != nil);
        
        // We got some data, pass it up to our client.
        
        ResponsePacketStatus responsePacketStatus = [self _isValidPingResponsePacket:packet];
        
        BOOL canSendDelegate = (self.delegate != nil) && [self.delegate respondsToSelector:@selector(pingOperation:didRecieveResponse:withPingResult:)];
        
        switch (responsePacketStatus) {
            case kICMPPingValid:
                NSLog(@"Ping is valid.");
                break;
            case kICMPTimeExceeded:
                NSLog(@"Ping is valid, but TTL has run out");
                break;
            case kICMPInvalid:
                NSLog(@"Tough luck, your life sucks!");
            default:
                break;
        }
        
        const struct IPHeader * header = [[self class] ipHeaderFromPacket:packet];
        self.endDate = [NSDate date];

        NSString * ipAddr = nil;
        
        if(header != NULL) {
            char * arr = sourceAddress(header);
            ipAddr =  [[NSString alloc] initWithCString:arr encoding:1];
        }
        
        MMPingOperationData * data = [[MMPingOperationData alloc] init];
        data.status = responsePacketStatus;
        data.destinationComputer = ipAddr;
        data.pingDuration = ([self.endDate timeIntervalSince1970] - [self.startDate timeIntervalSince1970]);
        
        if (canSendDelegate) {
            [self.delegate pingOperation:self didRecieveResponse:packet withPingResult:data];
        }
    } else {
        
        // We failed to read the data, so shut everything down.
        
        if (err == 0) {
            err = EPIPE;
        }
        [self _didFailWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
    }
    
    free(buffer);
    
    // Note that we don't loop back trying to read more data.  Rather, we just
    // let CFSocket call us again.
    [self _stopDataTransfer];
}

- (void)cancel {
    [self _stopDataTransfer];
}

#pragma mark - ICMP processor methods

+ (NSUInteger)_icmpHeaderOffsetInPacket:(NSData *)packet
// Returns the offset of the ICMPHeader within an IP packet.
{
    NSUInteger              result;
    const struct IPHeader * ipPtr;
    size_t                  ipHeaderLength;
    
    result = NSNotFound;
    if ([packet length] >= (sizeof(IPHeader) + sizeof(ICMPHeader))) {
        ipPtr = (const IPHeader *) [packet bytes];
        assert((ipPtr->versionAndHeaderLength & 0xF0) == 0x40);     // IPv4
        assert(ipPtr->protocol == 1);                               // ICMP
        ipHeaderLength = (ipPtr->versionAndHeaderLength & 0x0F) * sizeof(uint32_t);
        if ([packet length] >= (ipHeaderLength + sizeof(ICMPHeader))) {
            result = ipHeaderLength;
        }
    }
    return result;
}

+ (IPHeader *)ipHeaderFromPacket:(NSData *)packet {
    
    struct IPHeader * ipPtr = NULL;
    
    if(packet.length >= sizeof(IPHeader)) {
        ipPtr = (IPHeader *)[packet bytes];
    }
    
    return ipPtr;

}

- (ResponsePacketStatus)_isValidPingResponsePacket:(NSMutableData *)packet
// Returns true if the packet looks like a valid ping response packet destined
// for us.
{
    ResponsePacketStatus    result;
    NSUInteger              icmpHeaderOffset;
    ICMPHeader *            icmpPtr;
    uint16_t                receivedChecksum;
    uint16_t                calculatedChecksum;
    
    result = kICMPInvalid;
    
    icmpHeaderOffset = [[self class] _icmpHeaderOffsetInPacket:packet];
    if (icmpHeaderOffset != NSNotFound) {
        icmpPtr = (struct ICMPHeader *) (((uint8_t *)[packet mutableBytes]) + icmpHeaderOffset);
        
        receivedChecksum   = icmpPtr->checksum;
        icmpPtr->checksum  = 0;
        calculatedChecksum = in_cksum(icmpPtr, [packet length] - icmpHeaderOffset);
        icmpPtr->checksum  = receivedChecksum;
        
        
        switch (icmpPtr->type) {
            case kICMPTypeEchoReply: {
                if(calculatedChecksum == receivedChecksum) {
                    if ( OSSwapBigToHostInt16(icmpPtr->identifier) == self.identifier ) {
                        if ( OSSwapBigToHostInt16(icmpPtr->sequenceNumber) < self.nextSequenceNumber ) {
                            result = kICMPPingValid;
                        }
                    }
                } else {
                    result = kICMPInvalid;
                }
            }
                break;
            case kIMCPTypeTimeExceeded:
            {
                if (icmpPtr->code == kICMPCodeDefault) {
                    result = kICMPTimeExceeded;
                }
            }
                break;
            default:
                break;
        }
    }
    
    return result;
}


- (void)_didFailWithError:(NSError *)error {
    if(self.delegate) {
        [self.delegate pingOperation:self errorSendingPacket:nil withError:error];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

void SocketReadCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    MMPingOperation *    obj;
    
    obj = (__bridge MMPingOperation *) info;
    assert([obj isKindOfClass:[MMPingOperation class]]);
    
#pragma unused(s)
    assert(s == obj->_currentWorkingSocket);
#pragma unused(type)
    assert(type == kCFSocketReadCallBack);
#pragma unused(address)
    assert(address == nil);
#pragma unused(data)
    assert(data == nil);
    
    [obj _readDataFromSocket:obj->_currentWorkingSocket];
}


uint16_t in_cksum(const void *buffer, size_t bufferLen)
// This is the standard BSD checksum code, modified to use modern types.
{
	size_t              bytesLeft;
    int32_t             sum;
	const uint16_t *    cursor;
	union {
		uint16_t        us;
		uint8_t         uc[2];
	} last;
	uint16_t            answer;
    
	bytesLeft = bufferLen;
	sum = 0;
	cursor = buffer;
    
	/*
	 * Our algorithm is simple, using a 32 bit accumulator (sum), we add
	 * sequential 16 bit words to it, and at the end, fold back all the
	 * carry bits from the top 16 bits into the lower 16 bits.
	 */
	while (bytesLeft > 1) {
		sum += *cursor;
        cursor += 1;
		bytesLeft -= 2;
	}
    
	/* mop up an odd byte, if necessary */
	if (bytesLeft == 1) {
		last.uc[0] = * (const uint8_t *) cursor;
		last.uc[1] = 0;
		sum += last.us;
	}
    
	/* add back carry outs from top 16 bits to low 16 bits */
	sum = (sum >> 16) + (sum & 0xffff);	/* add hi 16 to low 16 */
	sum += (sum >> 16);			/* add carry */
	answer = ~sum;				/* truncate to 16 bits */
    
	return answer;
}

// Just clean up
- (void)_stopDataTransfer
{
    if (self->_currentWorkingSocket != NULL) {
        CFSocketInvalidate(self->_currentWorkingSocket);
        CFRelease(self->_currentWorkingSocket);
        self->_currentWorkingSocket = NULL;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////


@implementation MMPingOperationData

- (void)dealloc {
    [self destinationComputer];
}

@end
