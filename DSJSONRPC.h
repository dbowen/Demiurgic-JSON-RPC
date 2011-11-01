/*
 * DSJSONRPC.h
 *
 * Demiurgic JSON-RPC
 * Created by Derek Bowen on 10/20/2011.
 * 
 * Copyright (c) 2011 Demiurgic Software, LLC
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */


#import <Foundation/Foundation.h>

@class DSJSONRPC;

/**
 *  Used for identifying the type of error that occured in jsonRPC:didFailMethod:forId:withError:
 *
**/
typedef enum {
    DSJSONRPCNetworkError = 1,
    DSJSONRPCParseError = 2
} DSJSONRPCError;

/**
 *  Delegate used to provide information regarding web service calls made.
 *
**/
@protocol DSJSONRPCDelegate <NSObject>
@optional
/**
 *  Invoked upon the method successfully completing without the error key being set in the response.
 *
 *  methodResult will be the appropriate Objective-C object type based on the type set as the result on the server.
 *
**/
- (void)jsonRPC:(DSJSONRPC *)jsonRPC didFinishMethod:(NSString *)methodName forId:(NSInteger)aId withResult:(id)methodResult;

/**
 *  Invoked when the method is completed and the error key is set in the response.
 *
 *  methodError will be the appropriate Objective-C object type based on the type set as the error on the server.
 *
**/
- (void)jsonRPC:(DSJSONRPC *)jsonRPC didFinishMethod:(NSStream *)methodName forId:(NSInteger)aId withError:(id)methodError;

/**
 *  Invoked when an error occurs with the connection or when the JSON payload can't be (de)serialized.
 *
 *  The error number will be set to a value defined by DSJSONRPCError. 
 *  localizedDescription is the value from the original error that was generated.
 *
**/
- (void)jsonRPC:(DSJSONRPC *)jsonRPC didFailMethod:(NSString *)methodName forId:(NSInteger)aId withError:(NSError *)error;
@end


@interface DSJSONRPC : NSObject {
    id<DSJSONRPCDelegate> delegate;
    
@private
    NSURL               *_serviceEndpoint;
    NSDictionary        *_httpHeaders;
    NSMutableDictionary *_activeConnections;
}
- (id)initWithServiceEndpoint:(NSURL *)serviceEndpoint;
- (id)initWithServiceEndpoint:(NSURL *)serviceEndpoint andHTTPHeaders:(NSDictionary *)httpHeaders;

#pragma mark - Web Service Invocation Methods
- (NSInteger)callMethod:(NSString *)methodName;
- (NSInteger)callMethod:(NSString *)methodName withParameters:(id)methodParams;

@property (nonatomic, assign) id<DSJSONRPCDelegate> delegate;
@end
