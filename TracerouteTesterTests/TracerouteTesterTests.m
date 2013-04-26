//
//  TracerouteTesterTests.m
//  TracerouteTesterTests
//
//  Created by Bruno Bulic on 3/20/13.
//  Copyright (c) 2013 MarlinMobile. All rights reserved.
//

#import "TracerouteTesterTests.h"
#import "BBHostInfo.h"

#define ValidIPAddr                     @"192.168.0.1"
#define SomeHostName                    @"www.net.hr"
#define ValidIPV6Addr                   @"2607:f0d0:1002:51::4"
#define ValidIPV6Addr2                  @"1050:0000:0000:0000:0005:0600:300c:326b"
#define InvalidIPAddr                   @"233.412.5.8"
#define ValidButCouldBeWeirdIPV4Addr    @"0.192.168.1"

@implementation TracerouteTesterTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testRecognize_ValidIPAddr {
    BBHostInfo * info = [[BBHostInfo alloc] initWithHostNameOrNumber:ValidIPAddr];
    STAssertTrue(info.validAddress != NULL, @"Should not be null here.");
}

- (void)testRecognize_SomeHostName {
    BBHostInfo * info = [[BBHostInfo alloc] initWithHostNameOrNumber:SomeHostName];
    STAssertTrue([info validAddress] == NULL, @"Should be null here since I have it an Host Name");
}

- (void)testRecognize_ValidIPV6Addr{
    BBHostInfo * info = [[BBHostInfo alloc] initWithHostNameOrNumber:ValidIPV6Addr];
    STAssertTrue([info validAddress] != NULL, @"Should be null here since I have it an Host Name");
}

- (void)testRecognize_ValidIPV6Addr2 {
    BBHostInfo * info = [[BBHostInfo alloc] initWithHostNameOrNumber:ValidIPV6Addr2];
    STAssertTrue([info validAddress] != NULL, @"Should be null here since I have it an Host Name");
}
- (void)testRecognize_InvalidIPAddr {
    BBHostInfo * info = [[BBHostInfo alloc] initWithHostNameOrNumber:InvalidIPAddr];
    STAssertTrue([info validAddress] == NULL, @"Should be null here since I have it an Host Name");
}
- (void)testRecognize_ValidButCouldBeWeirdIPV4Addr {
    BBHostInfo * info = [[BBHostInfo alloc] initWithHostNameOrNumber:ValidButCouldBeWeirdIPV4Addr];
    STAssertTrue([info validAddress] != NULL, @"Should be null here since I have it an Host Name");
}


@end
