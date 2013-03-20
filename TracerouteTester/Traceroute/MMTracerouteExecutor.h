//
//  MMTracerouteTester.h
//  PingTester
//
//  Created by Bruno Bulić on 3/6/13.
//
//

#import <Foundation/Foundation.h>
#import "MMTracerouteDefines.h"
#import "MMPingOperation.h"

@class MMTracerouteExecutor;

@protocol MMTracerouteExecutorDelegate <NSObject>
@optional
- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor startedPingingWithTTL:(NSNumber *)ttl;
@required
- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor endedTracerouteWithSteps:(NSArray *)parrTracerouteSteps;
@end


@interface MMTracerouteExecutor : NSObject<MMPingOperationDelegate>

@property (nonatomic, readonly) NSString * hostName;
@property (nonatomic, unsafe_unretained) id<MMTracerouteExecutorDelegate> delegate;

- (id)initWithHostname:(NSString *)hn;

- (void)begin;
- (void)abort;

@end

@interface MMTracerouteStep : NSObject

@property (nonatomic, assign) uint32_t ttl;
@property (nonatomic, strong) NSString * recieverAddress;
@property (nonatomic, assign) NSTimeInterval pingDuration;

@end
