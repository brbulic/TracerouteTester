//
//  MMHostResolutionOperation.m
//  PingTester
//
//  Created by Bruno Bulić on 3/9/13.
//
//

#import "MMHostResolutionOperation.h"
#import "BBHostInfo.h"

#include    <sys/socket.h>
#include    <arpa/inet.h>

void MMHostInfoResolutionCallback(CFHostRef, CFHostInfoType , const CFStreamError *, void *);

@interface MMHostResolutionOperation ()

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;

@property (nonatomic, copy) MMHostResolutionOperationCallback callback;

@end

@implementation MMHostResolutionOperation {

    CFHostRef   _cfHostName;
}

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Use initWithHostName: to initiate the operation" userInfo:nil];
    
    return nil;
}

- (id)initWithHostName:(NSString *)hostname
{
    self = [super init];
    if (self) {
        _hostInformation = [[BBHostInfo alloc] initWithHostNameOrNumber:hostname];
    }
    return self;
}

- (void)startWithCallback:(MMHostResolutionOperationCallback)operation {
    
    if(self.callback != NULL ) return; // operation already running
    
    self.callback = operation;
    [self _startResolving];
    _isResolved = NO;
    
}

////////////////////////////////////////////////////////////

- (void)_startResolving {
    Boolean             success;
    CFHostClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    CFStreamError       streamError;
        
    BOOL dnsResolv = NO;
    
    if(self.hostInformation.hostName != nil) {
        _cfHostName = CFHostCreateWithName(CFAllocatorGetDefault(), (__bridge CFStringRef)self.hostInformation.hostName);
        dnsResolv = YES;
    }
    else if(self.hostInformation.hostAddress != nil) {
        
        struct sockaddr *sAddrResolve = [self.hostInformation validAddress];
        const UInt8 * ptr = (UInt8 *)sAddrResolve;
        CFDataRef addrDatarRef = CFDataCreate(CFAllocatorGetDefault(), ptr, sizeof(*sAddrResolve));
        _cfHostName = CFHostCreateWithAddress(CFAllocatorGetDefault(), addrDatarRef);
        _sockaddrBytes = (__bridge NSData *)addrDatarRef;
        CFRelease(addrDatarRef);
    } else {
        assert(NO);
    }
    
    assert(_cfHostName != NULL); // should have a host here
    
    CFHostSetClient(_cfHostName, MMHostInfoResolutionCallback, &context);
    CFHostScheduleWithRunLoop(_cfHostName, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
    self.startDate = [NSDate date];
    
    success = CFHostStartInfoResolution(_cfHostName, dnsResolv ? kCFHostAddresses : kCFHostNames, &streamError);
    
    if(!success) {
        [self _failedResolvingHostWithStreamError:streamError];
    }
}

// callback
void MMHostInfoResolutionCallback(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info)
{
    id userObject = (__bridge id)info;
    assert([userObject isKindOfClass:[MMHostResolutionOperation class]]);
    
    MMHostResolutionOperation * recievingEnd = (__bridge MMHostResolutionOperation *)info;
    assert(recievingEnd->_cfHostName    == theHost);    
    
    if(error != NULL && error->domain != 0) {
        [userObject _failedResolvingHostWithStreamError:*error];
    } else {
        [userObject completeOperationForType:typeInfo];
    }
}

// Failed Resolving
- (void)_failedResolvingHostWithStreamError:(CFStreamError) error {
    self.callback(kBBHostInfoResolutionTypeUnknown, nil, -1);
    
    self.callback = nil;
    _isResolved = false;
    
    [self _cleanUp];
}

//complete
- (void)completeOperationForType:(CFHostInfoType)infoType {
    
    Boolean isResolved;
    BBHostInfoResolutionType type = kBBHostInfoResolutionTypeUnknown;
    
    NSArray * resultValues;
    NSArray * arrayOfResults;
    
    self.endDate = [NSDate date];
    
    switch (infoType) {
        case kCFHostNames:
            resultValues = (__bridge NSArray *)CFHostGetNames(_cfHostName, &isResolved);
            type = kBBHostInfoResolutionTypeNames;
            break;
        case kCFHostAddresses:
            resultValues = (__bridge NSArray *)CFHostGetAddressing(_cfHostName, &isResolved);
            type = kBBHostInfoResolutionTypeAddresses;
            break;
        default:
            assert(FAIL);
            break;
    }
    
    if(resultValues != nil && isResolved) {
        switch (infoType) {
            case kCFHostAddresses:
                arrayOfResults = [self extractHostAddresses:resultValues];
                _ipStrings = arrayOfResults;
                break;
            case kCFHostNames:
                arrayOfResults = [self extractHostNames:resultValues];
                _hostNames = arrayOfResults;
                break;
            default:
                assert(FAIL);
                break;
        }
    }
    
    NSTimeInterval delta = [self.endDate timeIntervalSince1970] - [self.startDate timeIntervalSince1970];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.callback(type, arrayOfResults, delta);
        self.callback = nil;        
        [self _cleanUp];
    });
}

- (NSArray *)extractHostAddresses:(NSArray *)data {
    
    NSMutableArray * arrOfHostAddresses = [NSMutableArray arrayWithCapacity:data.count];
    for (NSData * addrData in data) {
        
        // byte memory representation of sockaddr_in
        const struct sockaddr * pSa = (const struct sockaddr *)[addrData bytes];
        
        const char * pSzIpAddrCstringReadable;
        
        if (pSa->sa_family == AF_INET) {
            char addrNamev4[INET_ADDRSTRLEN];
            const struct sockaddr_in * ipv4 = (const struct sockaddr_in*)pSa;
            const char * result = inet_ntop(pSa->sa_family,  &(ipv4->sin_addr), addrNamev4, INET_ADDRSTRLEN);
            assert(addrNamev4 == result);
            
            _isResolved = YES;
            _sockaddrBytes = addrData; // have socket address;
            
            pSzIpAddrCstringReadable = result;
            
        } else if(pSa->sa_family == AF_INET6) {
            char addrNamev6[INET6_ADDRSTRLEN];
            
            const struct sockaddr_in6 * ipv6 = (const struct sockaddr_in6*)pSa;
            const char * result = inet_ntop(ipv6->sin6_family,  &(ipv6->sin6_addr), addrNamev6, INET6_ADDRSTRLEN);
            assert(addrNamev6 == result);
            
            pSzIpAddrCstringReadable = result;
        } else {
            // just fail, what kind of protocol is that?
            assert(false);
        }
        
        NSString * str = [NSString stringWithCString:pSzIpAddrCstringReadable encoding:NSASCIIStringEncoding];
        [arrOfHostAddresses addObject:str];
    }
    
    return [NSArray arrayWithArray:arrOfHostAddresses];
}

- (NSArray *)extractHostNames:(NSArray *)data {
    
    NSMutableArray * arrOfHostAddresses = [NSMutableArray arrayWithCapacity:data.count];
    for (NSString *ref in data) {
        [arrOfHostAddresses addObject:ref];
    }

    return [NSArray arrayWithArray:arrOfHostAddresses];
}

- (void)_compileResultsFromCallbacks {
    
}

- (void)_cleanUp {
    if (_cfHostName != NULL) {
        CFHostSetClient(self->_cfHostName, NULL, NULL);
        CFHostUnscheduleFromRunLoop(self->_cfHostName, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(self->_cfHostName);
        self->_cfHostName = NULL;
    }
}

@end
