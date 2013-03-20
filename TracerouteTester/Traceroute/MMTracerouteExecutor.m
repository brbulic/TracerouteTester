//
//  MMTracerouteTester.m
//  PingTester
//
//  Created by Bruno Bulić on 3/6/13.
//
//

#import "MMTracerouteExecutor.h"
#import "MMHostResolutionOperation.h"

@interface MMTracerouteExecutor ()

- (void)_doHostResolve;
- (void)_doAbort;

- (void)_startPing;

@property (nonatomic, strong) MMHostResolutionOperation * currentOperation;
@property (nonatomic, strong) MMPingOperation           * pingOperation;
@property (nonatomic, assign) NSUInteger                hop;

@property (nonatomic, strong) NSMutableArray            * pingSteps;

- (NSNumber *)getCurrentTTL;

@end

@implementation MMTracerouteExecutor {
    NSUInteger hostResolveFailCount;
}

- (id)initWithHostname:(NSString *)hn
{
    self = [super init];
    if (self) {
        _hostName = hn;
        self.pingSteps = [NSMutableArray array];
        self.hop = 0;
    }
    return self;
}

- (void)begin {
    //
    if(!self.currentOperation) {
        [self _doHostResolve];
    } else {
        [self _startPing];
    }
}

- (void)_doHostResolve {
    
    if(hostResolveFailCount == 3){
        [self abort];
        return;
    }
    
    MMHostResolutionOperation * currentOperation = [[MMHostResolutionOperation alloc] initWithHostName:self.hostName];
    
    self.currentOperation = currentOperation;
    
    [self.currentOperation startWithCallback:^(NSArray *ipAdressesInNSString, NSTimeInterval resolutionDurationSeconds) {
        [self onSuccess];
    }];
}

- (NSNumber *)getCurrentTTL {
    return [NSNumber numberWithInt:++self.hop];
}


- (void)_startPing {
    
    MMPingOperation * operation = [[MMPingOperation alloc] initWithHostAddress:self.currentOperation.hostAddress];
    
    self.pingOperation = operation;
    self.pingOperation.delegate = self;
    NSNumber * number = [self getCurrentTTL];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.delegate && [self.delegate respondsToSelector:@selector(tracerouteExecutor:startedPingingWithTTL:)]) {
            [self.delegate tracerouteExecutor:self startedPingingWithTTL:number];
        }
    });
    
    [self.pingOperation beginPingWithTtl:number];
}

-(void)pingOperation:(MMPingOperation *)po errorSendingPacket:(NSData *)packet withError:(NSError *)error {
    [self.pingOperation cancel];
    [self setPingOperation:nil];
}

- (void)pingOperation:(MMPingOperation *)po didSendPacket:(NSData *)packet {
    
}

- (void)pingOperation:(MMPingOperation *)po didRecieveResponse:(NSData *)packet withPingResult:(MMPingOperationData *)status {
    
    MMTracerouteStep * step = [[MMTracerouteStep alloc] init];
    
    if(status.status != kICMPInvalid) {
        step.ttl = self.hop;
        step.recieverAddress = [status.destinationComputer substringToIndex:(status.destinationComputer.length-1)];
        step.pingDuration = status.pingDuration;

    } else {
        step.ttl = INT_MIN;
        step.recieverAddress = nil;
    }
    
    [self.pingSteps addObject:step];
    
    switch (status.status) {
        case kICMPTimeExceeded: {
            self.pingOperation = nil;
            [self _startPing];
        }
            break;
        case kICMPPingValid: {
            
            if(self.delegate && [self.delegate respondsToSelector:@selector(tracerouteExecutor:endedTracerouteWithSteps:)]) {
                [self.delegate tracerouteExecutor:self endedTracerouteWithSteps:self.pingSteps];
            }
        }
            break;
        case kICMPInvalid:
            NSLog(@"Failed on %d hop.", self.hop);
        default:
            break;
    }
}

- (void)onSuccess {
    if(self.currentOperation.isResolved) {
        [self _startPing];
    } else {
        [self _doHostResolve]; // loop endlessy before getting the address.
        hostResolveFailCount ++;
    }
}

- (void)abort {
    // do some abort sh1t
}

- (void)_doAbort {
    // real abort shit;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MMTracerouteStep


@end
