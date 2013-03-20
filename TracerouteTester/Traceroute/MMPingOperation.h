//
//  MMPingOperation.h
//  PingTester
//
//  Created by Bruno Bulić on 3/10/13.
//
//

#import <Foundation/Foundation.h>
#import "MMTracerouteDefines.h"

@class MMPingOperation;
@class MMTracerouteExecutor;
@class MMPingOperationData;

@protocol MMPingOperationDelegate <NSObject>
@optional
- (void)pingOperation:(MMPingOperation *)po didSendPacket:(NSData *)packet;
@required
- (void)pingOperation:(MMPingOperation *)po errorSendingPacket:(NSData *)packet withError:(NSError *)error;
- (void)pingOperation:(MMPingOperation *)po didRecieveResponse:(NSData *)packet withPingResult:(MMPingOperationData *)status;
@end


@interface MMPingOperation : NSObject

@property (nonatomic, unsafe_unretained) id<MMPingOperationDelegate> delegate;

- (id)initWithHostAddress:(NSData *)hostAddress;
- (id)initWithHostAddressString:(NSString *)hostAddress;

/// Set number as nil to use default TTL
- (void)beginPingWithTtl:(NSNumber *)number;
- (void)cancel;

@end

@interface MMPingOperationData : NSObject

@property (nonatomic, assign) ResponsePacketStatus status;
@property (nonatomic, strong) NSString * destinationComputer;
@property (nonatomic, assign) NSTimeInterval pingDuration;

@end
