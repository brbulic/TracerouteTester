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
@class MMTracerouteStep;

#define MMTracerouteStepFailedStepDataErrorKey @"MMTracerouteStepFailedStepDataErrorKey"

@protocol MMTracerouteExecutorDelegate <NSObject>
@optional
- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor startedPingingWithTTL:(NSNumber *)ttl;
- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor traceRouteStepDone:(MMTracerouteStep *)step;
@required
- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor endedTracerouteWithSteps:(NSArray *)parrTracerouteSteps;
- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor tracerouteFailed:(NSError *)error;
@end


@interface MMTracerouteExecutor : NSObject<MMPingOperationDelegate>

@property (nonatomic, readonly) NSString * host; // could be a name or an address
@property (nonatomic, unsafe_unretained) id<MMTracerouteExecutorDelegate> delegate;

- (id)initWithHostname:(NSString *)hn;

- (void)begin;
- (void)abort;

@end

@interface MMTracerouteStep : NSObject

@property (nonatomic, assign) uint32_t ttl;
@property (nonatomic, strong) NSString * recieverHostName;
@property (nonatomic, strong) NSString * recieverAddress;
@property (nonatomic, assign) NSTimeInterval pingDuration;

@end
