//
//  MMViewController.m
//  TracerouteTester
//
//  Created by Bruno Bulic on 3/20/13.
//  Copyright (c) 2013 MarlinMobile. All rights reserved.
//

#import "MMViewController.h"

@interface MMViewController ()

@property (nonatomic, strong) MMTracerouteExecutor * executor;
@property (nonatomic, strong) NSMutableString * statusMessage;

@end

@implementation MMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor endedTracerouteWithSteps:(NSArray *)parrTracerouteSteps {
    
    [self.statusMessage appendFormat:@"\nTraceroute is dooooneeee!"];
    [self end];
}


-(void)tracerouteExecutor:(MMTracerouteExecutor *)executor tracerouteFailed:(NSError *)error {
    
    [self.statusMessage appendFormat:@"\n%@",error.domain];
    [self end];
}

- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor traceRouteStepDone:(MMTracerouteStep *)step {
    
    [self.statusMessage appendFormat:@"\n-> %d) - (%@) responded in %0.2f ms",step.ttl, step.recieverAddress, (step.pingDuration * 1000)];
    self.resultTestView.text = self.statusMessage;
}

- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor startedPingingWithTTL:(NSNumber *)ttl {
    
}

- (void)end {
    self.resultTestView.text = self.statusMessage;
    self.hostnameField.enabled = YES;
    self.confirmButton.enabled = YES;
}

- (IBAction)buttonTapped:(id)sender {
    
    if(self.hostnameField.text != nil && self.hostnameField.text.length > 0) {
        self.executor = [[MMTracerouteExecutor alloc] initWithHostname:self.hostnameField.text];
        self.executor.delegate = self;
        [self.executor begin];
        
        self.statusMessage = [NSMutableString stringWithFormat:@"Started ping with steps:"];
        
        self.hostnameField.enabled = NO;
        self.confirmButton.enabled = NO;
    }
}
@end
