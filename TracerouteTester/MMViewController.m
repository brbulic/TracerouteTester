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
    
    NSMutableString * string = [NSMutableString stringWithFormat:@"Ended ping with steps:"];
    
    for (MMTracerouteStep * step in parrTracerouteSteps) {
        
        [string appendFormat:@"\n-> %d) - (%@) responded in %0.2f ms",step.ttl, step.recieverAddress, (step.pingDuration * 1000)];
    }
    
    self.hostnameField.enabled = YES;
    self.confirmButton.enabled = YES;
    self.resultTestView.text = [NSString stringWithString:string];
}

- (void)tracerouteExecutor:(MMTracerouteExecutor *)executor startedPingingWithTTL:(NSNumber *)ttl {
    
}

- (IBAction)buttonTapped:(id)sender {
    
    if(self.hostnameField.text != nil && self.hostnameField.text.length > 0) {
        self.executor = [[MMTracerouteExecutor alloc] initWithHostname:self.hostnameField.text];
        self.executor.delegate = self;
        [self.executor begin];
    }
    
    self.hostnameField.enabled = NO;
    self.confirmButton.enabled = NO;
}
@end
