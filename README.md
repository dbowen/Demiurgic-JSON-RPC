# Demiurgic JSON-RPC for Objective-C (iOS, Mac)

Demiurgic JSON-RPC is a lightweight and easy to use wrapper for making JSON-RPC 2.0 calls in Objective-C.

We're working to provide better documentation for the API.  If you need assistance please feel free to contact us and we'll be glad to help!

# Installation

1. In your XCode Project, add all the .h and .m files from the Source folder into your project. 
2. Import *DSJSONRPC.h* in any file where you wish to make JSON-RPC web service calls.
3. Starting consuming web services without all the hassle of managing the communication yourself!

# ARC Support

Version 1.1.0 of Demiurgic JSON-RPC now has support for ARC.  However, if you wish to continue using the 1.0.0 version, this can be done by adding the *-fno-objc-arc* flag to the following files:

* DSJSONRPC.m
* JSONKit.m

# Usage

## Setting up the instance

First import the header file *DSJSONRPC.h* in the file you'd like to do web service calls from.

Once its included, simply create a new instance of the class in one of two ways:

  1) DSJSONRPC *jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:(NSString *)serviceEndpoint];
	Service endpoint is the location of the web service where all calls will be made.

	Example:
		DSJSONRPC *jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:@"https://www.yourwebsite.com/MyWebservice.php"];

  2) DSJSONRPC *jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:(NSString *)serviceEndpoint andHTTPHeaders:(NSDictionary *)httpHeaders;
	The same as above, however you can specify customer HTTP headers to include with your request.

	Example:
		NSDictionary *customHeaders = [NSDictionary dictionaryWithObjectsAndKeys:@"MyApplication/1.00", @"User-Agent", nil];
		DSJSONRPC *jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:@"https://www.yourwebsite.com/MyWebservice.php" withHTTPHeaders:customHeaders];

## Making a web service call

Demiurgic JSON-RPC can be used in one of two ways.  The first is to use a more traditional approach with delegates, or with completion handler blocks.  Using completion handlers is our recommendation for any new applications.

Lets assume our web service has a method called echo.  It takes in dictionary with the key "message", which is a string that will be echoed back to the client.

1) Completion Handler Based

	[jsonRPC callMethod:@"echo" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Hello, World!", @"message", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
		// Use the server response data here.  You should always ensure that methodError and error are nil first, and handle them accordingly.
	}];

2) Delegate Based

	[jsonRPC callMethod:@"echo" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Hello, World!", @"message", nil]];
	// All responses will be given to the delegate specified.