//
//  DSJSONRPCError.m
//  TestAnyMethod
//
//  Created by Derek Bowen on 11/1/11.
//  Copyright (c) 2011 Demiurgic Software, LLC. All rights reserved.
//

#import "DSJSONRPCError.h"

@implementation DSJSONRPCError

@synthesize code, message, data;

- (id)initWithErrorData:(NSDictionary *)errorData {
    if (!(self = [super init]))
        return self;
    
    code    = [[errorData objectForKey:@"code"] intValue];
    message = [[errorData objectForKey:@"message"] retain];
    data    = [[errorData objectForKey:@"data"] retain];
    
    return self;
}

+ (DSJSONRPCError *)errorWithData:(NSDictionary *)errorData {
    return [[[self alloc] initWithErrorData:errorData] autorelease];
}

- (void)dealloc {
    [message release], message = nil;
    [data release], data = nil;
    
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DSJSONRPC Error: %@ (Code: %i) - Data: %@", self.message, self.code, self.data];
}

@end
