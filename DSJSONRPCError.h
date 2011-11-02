//
//  DSJSONRPCError.h
//  TestAnyMethod
//
//  Created by Derek Bowen on 11/1/11.
//  Copyright (c) 2011 Demiurgic Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    JSONRPCParseError = -32700,
    JSONRPCInvalidRequest = -32600,
    JSONRPCMethodNotFound = -32601,
    JSONRPCInvalidParams = -32602,
    JSONRPCInternalError = -32603
} JSONRPCErrorType;


@interface DSJSONRPCError : NSObject {
    NSInteger   code;
    NSString    *message;
    id          data;
}
- (id)initWithErrorData:(NSDictionary *)errorData;
+ (DSJSONRPCError *)errorWithData:(NSDictionary *)errorData;

@property (nonatomic, readonly) NSInteger   code;
@property (nonatomic, readonly) NSString    *message;
@property (nonatomic, readonly) id          data;

@end
