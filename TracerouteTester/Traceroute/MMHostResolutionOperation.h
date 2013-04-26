//
//  MMHostResolutionOperation.h
//  PingTester
//
//  Created by Bruno Bulić on 3/9/13.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    kBBHostInfoResolutionTypeNames,
    kBBHostInfoResolutionTypeAddresses,
    kBBHostInfoResolutionTypeUnknown
} BBHostInfoResolutionType;

@class BBHostInfo;

typedef void(^MMHostResolutionOperationCallback)(BBHostInfoResolutionType resolveType, NSArray * resolveData, NSTimeInterval resolutionDurationSeconds);

@interface MMHostResolutionOperation : NSObject

- (id)initWithHostName:(NSString *)hostname;

@property (nonatomic, readonly) BOOL isResolved;
@property (nonatomic, readonly) BBHostInfo * hostInformation;

@property (nonatomic, readonly) NSData* sockaddrBytes;

@property (nonatomic, readonly) NSArray * ipStrings;
@property (nonatomic, readonly) NSArray * hostNames;

- (void)startWithCallback:(MMHostResolutionOperationCallback)operation;

@end
