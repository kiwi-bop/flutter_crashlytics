#import <Foundation/Foundation.h>
#import "Fabric.h"
#import "Crashlytics.h"
#import "FlutterCrashlyticsPlugin.h"

@implementation FlutterException {
    NSArray <CLSStackFrame *> *frameArray;
    NSArray <NSString *> *callStackSymbols;
}

- (instancetype)initWithName:(NSExceptionName)aName reason:(nullable NSString *)aReason frameArray:(NSArray<CLSStackFrame *> *)array {
    self = [super initWithName:aName reason:aReason userInfo:nil];
    if (self) {
        NSMutableArray<NSString *> *data = [[NSMutableArray <NSString *> alloc] initWithCapacity:frameArray.count];
        for (NSUInteger i = 0; i < frameArray.count; ++i) {
            [data insertObject:frameArray[i].description atIndex:i];
        }

        frameArray = array;
        callStackSymbols = data;
    }
    return self;
}
@end

@implementation FlutterCrashlyticsPlugin {
    BOOL _isFabricInitialized;
}

+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"flutter_crashlytics" binaryMessenger:[registrar messenger]];
    FlutterCrashlyticsPlugin *instance = [[FlutterCrashlyticsPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        [Fabric with:@[[Crashlytics self]]];
        _isFabricInitialized = true;
        result(nil);
    } else if (_isFabricInitialized) {
        [self onInitialisedMethodCall:call result:result];
    } else {
        // Should not result in an error. Otherwise Opt Out clients would need to handle errors
        result(nil);
    }
}

- (void)onInitialisedMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    Crashlytics *crashlytics = [Crashlytics sharedInstance];

    if ([@"reportCrash" isEqualToString:call.method]) {
        NSDictionary *exception = call.arguments;

        NSString *cause = [self getValueForKey:@"cause" from:exception orDefaultTo:@"Flutter Error"];
        NSString *message = [self getValueForKey:@"message" from:exception orDefaultTo:@""];
        NSArray<NSDictionary *> *traces = exception[@"trace"];
        BOOL forceCrash = [exception[@"forceCrash"] boolValue] ? [exception[@"forceCrash"] boolValue] : false;
        NSArray<CLSStackFrame *> *stacks = [self buildStackTrace:traces];

        if (forceCrash) {
            [self crash:cause reason:message frames:stacks];
        } else {
            [crashlytics recordCustomExceptionName:cause reason:message frameArray:stacks];
        }
        result(nil);
    } else if ([@"log" isEqualToString:call.method]) {
        if ([call.arguments isKindOfClass:[NSString class]]) {
            CLSLog(@"%@", call.arguments);
        } else {
            NSArray *info = call.arguments;
            CLSLog(@"%@: %@ %@", info[0], info[1], info[2]);
        }

        result(nil);
    } else if ([@"setInfo" isEqualToString:call.method]) {
        NSDictionary *info = call.arguments;

        [crashlytics setObjectValue:info[@"value"] forKey:info[@"key"]];

        result(nil);
    } else if ([@"setUserInfo" isEqualToString:call.method]) {
        NSDictionary *info = call.arguments;

        [crashlytics setUserName:info[@"name"]];
        [crashlytics setUserEmail:info[@"email"]];
        [crashlytics setUserIdentifier:info[@"id"]];

        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (NSString *)getValueForKey:(NSString *)key from:(NSDictionary *)dictionary orDefaultTo:(NSString *)defaultValue {
    NSString *value = dictionary[key];
    /// Dart [null] returns nil or NSNull when nested.
    if (value != nil && ![value isEqual:[NSNull null]]) {
        return value;
    } else {
        return defaultValue;
    }
}

- (NSArray<CLSStackFrame *> *)buildStackTrace:(NSArray<NSDictionary *> *)traces {
    NSMutableArray<CLSStackFrame *> *stacks = [[NSMutableArray<CLSStackFrame *> alloc] initWithCapacity:traces.count];

    for (NSUInteger i = 0; i < traces.count; i++) {
        NSDictionary *trace = traces[i];

        NSString *className = [self getValueForKey:@"class" from:trace orDefaultTo:@""];
        NSString *methodName = [self getValueForKey:@"method" from:trace orDefaultTo:@""];
        NSString *libraryName = [self getValueForKey:@"library" from:trace orDefaultTo:@""];
        NSString *symbol = [NSString stringWithFormat:@"%@.%@", className, methodName];

        CLSStackFrame *frame = [CLSStackFrame stackFrameWithSymbol:symbol];
        [frame setLibrary:className];
        [frame setRawSymbol:className];
        [frame setFileName:libraryName];

        if (trace[@"line"] != nil && ![trace[@"line"] isEqual:[NSNull null]]) {
            [frame setLineNumber:(uint32_t) trace[@"line"]];
        }

        [stacks insertObject:frame atIndex:i];
    }

    return stacks;
}

- (void)crash:(NSString *)cause reason:(NSString *)reason frames:(NSArray<CLSStackFrame *> *)frameArray {

    CLSLog(@"%@ %@", cause, reason);
    NSMutableString *stack = [NSMutableString string];
    for (NSUInteger i = 0; i < [frameArray count]; ++i) {
        [stack appendString: frameArray[i].description];
        [stack appendString: @"\n"];
    }
    CLSLog(@"%@", stack);
    
    FlutterException *ex = [[FlutterException alloc] initWithName:cause reason:reason frameArray:frameArray];

    [ex raise];
}

@end
