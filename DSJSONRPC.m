/*
 * DSJSONRPC.m
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

#import "DSJSONRPC.h"
#import "JSONKit.h"

#ifdef __OBJC_GC__
#error Demiurgic JSON-RPC does not support Objective-C Garbage Collection
#endif

#if __has_feature(objc_arc)
#error Demiurgic JSON-RPC does not support Objective-C Automatic Reference Counting (ARC)
#endif


@interface DSJSONRPC () // Private
@property (nonatomic, retain) NSURL               *_serviceEndpoint;
@property (nonatomic, retain) NSDictionary        *_httpHeaders;
@property (nonatomic, retain) NSMutableDictionary *_activeConnections;
@end

@implementation DSJSONRPC

@synthesize delegate;
@synthesize _serviceEndpoint, _httpHeaders, _activeConnections;

- (id)initWithServiceEndpoint:(NSURL *)serviceEndpoint; {
    return [self initWithServiceEndpoint:serviceEndpoint andHTTPHeaders:nil];
}

- (id)initWithServiceEndpoint:(NSURL *)serviceEndpoint andHTTPHeaders:(NSDictionary *)httpHeaders {
    if (!(self = [super init]))
        return self;
    
    self._serviceEndpoint = serviceEndpoint;
    self._httpHeaders     = httpHeaders;
    
    // Create dictionary to hold active conenctions
    self._activeConnections = [NSMutableDictionary dictionary];
    
    return self;
}

- (void)dealloc {
    [_serviceEndpoint release], _serviceEndpoint = nil;
    [_httpHeaders release], _httpHeaders = nil;
    [_activeConnections release], _activeConnections = nil;
    
    [super dealloc];
}

#pragma mark - Web Service Invocation Methods

- (NSInteger)callMethod:(NSString *)methodName {
    return [self callMethod:methodName withParameters:nil];
}

- (NSInteger)callMethod:(NSString *)methodName withParameters:(id)methodParams {
    // Set parameters to NSNull if they weren't provided
    if (methodParams == nil) {
        methodParams = [NSNull null];
    }
    
    // Generate a random Id for the call
    NSInteger aId = arc4random();
    
    // Setup the JSON-RPC call payload
    NSArray *methodKeys = [NSArray arrayWithObjects:@"jsonrpc", @"method", @"params", @"id", nil];
    NSArray *methodObjs = [NSArray arrayWithObjects:@"2.0", methodName, methodParams, [NSNumber numberWithInt:aId], nil];
    NSDictionary *methodCall = [NSDictionary dictionaryWithObjects:methodObjs forKeys:methodKeys];
    
    // Attempt to serialize the call payload to a JSON string
    NSError *error;
    NSData *postData = [methodCall JSONDataWithOptions:JKSerializeOptionNone error:&error];
    
    // TODO: Make this a parameter??
    if (error != nil) {
        if (delegate && [delegate respondsToSelector:@selector(jsonRPC:didFailMethod:forId:withError:)]) {
            NSError *aError = [NSError errorWithDomain:@"com.demiurgicsoftware.json-rpc" code:DSJSONRPCParseError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], NSLocalizedDescriptionKey, nil]];
            
            [delegate jsonRPC:self didFailMethod:methodName forId:aId withError:aError];
        }
    }
    
    // Create the JSON-RPC request
    NSMutableURLRequest *serviceRequest = [NSMutableURLRequest requestWithURL:self._serviceEndpoint];
    [serviceRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [serviceRequest setValue:@"DSJSONRPC/1.0" forHTTPHeaderField:@"User-Agent"];
    
    // Add custom HTTP headers
    for (id key in self._httpHeaders) {
        [serviceRequest setValue:[self._httpHeaders objectForKey:key] forHTTPHeaderField:key];
    }
    
    // Finish creating request, we set content-length after user headers to prevent user error
    [serviceRequest setValue:[NSString stringWithFormat:@"%i", postData.length] forHTTPHeaderField:@"Content-Length"];
    [serviceRequest setHTTPMethod:@"POST"];
    [serviceRequest setHTTPBody:postData];
    
    // Create dictionary to store information about the request so we can recall it later
    NSMutableDictionary *connectionInfo = [NSMutableDictionary dictionaryWithCapacity:3];
    [connectionInfo setObject:methodName forKey:@"method"];
    [connectionInfo setObject:[NSNumber numberWithInt:aId] forKey:@"id"];
    
    // Perform the JSON-RPC method call
    NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:serviceRequest delegate:self];
    [self._activeConnections setObject:connectionInfo forKey:[NSNumber numberWithInt:(int)aConnection]];
    
    return aId;
}


#pragma mark - Runtime Method Invocation Handling

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    // Determine if we handle the method signature
    // If not, create one so it goes to forwardInvocation
    NSMethodSignature *aMethodSignature;
    if (!(aMethodSignature = [super methodSignatureForSelector:aSelector]))
        aMethodSignature = [NSMethodSignature signatureWithObjCTypes:"@:@@@"];
    
    return aMethodSignature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    // Get method name from invocation
    NSString *selectorName = NSStringFromSelector(anInvocation.selector);
    NSString *methodName = [[selectorName componentsSeparatedByString:@":"] objectAtIndex:0];
    
    // Get reference to the first argument passed in
    id methodParams;
    [anInvocation getArgument:&methodParams atIndex:2];
    
    // If no parameters were given or its not a valid primative type, then pass in nil
    if (methodParams == nil || !([methodParams isKindOfClass:[NSArray class]] || [methodParams isKindOfClass:[NSDictionary class]] || [methodParams isKindOfClass:[NSString class]] || [methodParams isKindOfClass:[NSNumber class]])) {
        methodParams = nil;
    }
        
    // Rebuild the invocation request and invoke it
    [anInvocation setSelector:@selector(callMethod:withParameters:)];
    [anInvocation setArgument:&methodName atIndex:2];
    [anInvocation setArgument:&methodParams atIndex:3];
    [anInvocation invokeWithTarget:self];
}


#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSMutableDictionary *connectionInfo = [self._activeConnections objectForKey:[NSNumber numberWithInt:(int)connection]];
    [connectionInfo setObject:[NSMutableData data] forKey:@"data"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSMutableDictionary *connectionInfo = [self._activeConnections objectForKey:[NSNumber numberWithInt:(int)connection]];
    NSMutableData *connectionData = [connectionInfo objectForKey:@"data"];
    [connectionData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSNumber *connectionKey = [NSNumber numberWithInt:(int)connection];
    NSMutableDictionary *connectionInfo = [self._activeConnections objectForKey:connectionKey];
    [self._activeConnections removeObjectForKey:connectionKey];
    [connection release];
    
    if (delegate && [delegate respondsToSelector:@selector(jsonRPC:didFailMethod:forId:withError:)]) {
        NSError *aError = [NSError errorWithDomain:@"com.demiurgicsoftware.json-rpc" code:DSJSONRPCNetworkError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], NSLocalizedDescriptionKey, nil]];
        
        [delegate jsonRPC:self didFailMethod:[connectionInfo objectForKey:@"name"] forId:[[connectionInfo objectForKey:@"id"] intValue] withError:aError];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Get information about the connection
    NSNumber *connectionKey = [NSNumber numberWithInt:(int)connection];
    NSMutableDictionary *connectionInfo = [self._activeConnections objectForKey:connectionKey];
    NSMutableData *connectionData = [connectionInfo objectForKey:@"data"];
    
    // Attempt to deserialize result
    NSError *error = nil;
    NSDictionary *jsonResult = [connectionData objectFromJSONDataWithParseOptions:JKParseOptionNone error:&error];
    if (error) {
        // Pass the error to the delegate if they care
        if (delegate && [delegate respondsToSelector:@selector(jsonRPC:didFailMethod:forId:withError:)]) {
            NSError *aError = [NSError errorWithDomain:@"com.demiurgicsoftware.json-rpc" code:DSJSONRPCParseError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], NSLocalizedDescriptionKey, nil]];
            
            [delegate jsonRPC:self didFailMethod:[connectionInfo objectForKey:@"method"] forId:[[connectionInfo objectForKey:@"id"] intValue] withError:aError];
        }
    }
    
    // The JSON server passed back and error for the response
    if (!error && [jsonResult objectForKey:@"error"] != nil && [[jsonResult objectForKey:@"error"] isKindOfClass:[NSDictionary dictionary]]) {
        // Give the error to the delegate if they care
        if (delegate && [delegate respondsToSelector:@selector(jsonRPC:didFinishMethod:forId:withError:)]) {
            DSJSONRPCError *jsonRPCError = [DSJSONRPCError errorWithData:[jsonResult objectForKey:@"error"]];
            [delegate jsonRPC:self didFinishMethod:[connectionInfo objectForKey:@"method"] forId:[[connectionInfo objectForKey:@"id"] intValue] withError:jsonRPCError];
        }
    }
    // Not error, give delegate the method result
    else if (!error && delegate && [delegate respondsToSelector:@selector(jsonRPC:didFinishMethod:forId:withResult:)]) {
        [delegate jsonRPC:self didFinishMethod:[connectionInfo objectForKey:@"method"] forId:[[connectionInfo objectForKey:@"id"] intValue] withResult:[jsonResult objectForKey:@"result"]];
    }
    
    // Remove the connection from active connections
    [self._activeConnections removeObjectForKey:connectionKey];
    [connection release];
}

@end
