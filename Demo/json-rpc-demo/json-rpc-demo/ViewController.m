//
//  ViewController.m
//  json-rpc-demo
//
//  Created by Derek Bowen on 7/17/12.
//  Copyright (c) 2012 Demiurgic Software, LLC. All rights reserved.
//

#import "ViewController.h"
#import "DSJSONRPC.h"

@interface ViewController ()

@property (strong, nonatomic) DSJSONRPC *_jsonRPC;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self._jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:@"http://www.raboof.com/projects/jayrock/demo.ashx"]];
    
    // We're going to use a standard completion handler for our json-rpc calls
    DSJSONRPCCompletionHandler completionHandler = ^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
        if (methodError) {
            NSLog(@"\nMethod %@(%i) returned an error: %@\n\n", methodName, callId, methodError);
        }
        else if (internalError) {
            NSLog(@"\nMethod %@(%i) couldn't be sent with error: %@\n\n", methodName, callId, internalError);
        }
        else {
            NSLog(@"\nMethod %@(%i) completed with result: %@\n\n", methodName, callId, methodResult);
        }
    };
    
    
    // Store generated call id to match up responses
    NSInteger callId;
    
    // Example of a method call with no parameters that returns a string representation of the current time
    callId = [self._jsonRPC callMethod:@"now" onCompletion:completionHandler];
    NSLog(@"\n*** now called with id: %i\n\n", callId);
    
    // Example of method call that takes one parameter named "text", and returns its value back
    callId = [self._jsonRPC callMethod:@"echo" withParameters:@{ @"text" : @"This will be returned." } onCompletion:completionHandler];
    NSLog(@"\n*** echo called with id: %i\n\n", callId);
    
    // Example of method call that takes two numbers and returns their sum
    callId = [self._jsonRPC callMethod:@"add" withParameters:@{ @"a" : [NSNumber numberWithInt:4], @"b" : [NSNumber numberWithInt:10] } onCompletion:completionHandler];
    NSLog(@"\n*** add called with id: %i\n\n", callId);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
