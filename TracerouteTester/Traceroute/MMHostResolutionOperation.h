//
//  MMHostResolutionOperation.h
//  PingTester
//
//  Created by Bruno Bulić on 3/9/13.
//
//

#import <Foundation/Foundation.h>

typedef void(^MMHostResolutionOperationCallback)(NSArray * ipAdressesInNSString, NSTimeInterval resolutionDurationSeconds);

@interface MMHostResolutionOperation : NSObject

- (id)initWithHostName:(NSString *)hostname;

@property (weak, nonatomic, readonly) NSString * hostName;
@property (nonatomic, readonly) BOOL isResolved;

@property (weak, nonatomic, readonly) NSData* hostAddress;
@property (weak, nonatomic, readonly) NSArray * ipStrings;

- (void)startWithCallback:(MMHostResolutionOperationCallback)operation;

@end
