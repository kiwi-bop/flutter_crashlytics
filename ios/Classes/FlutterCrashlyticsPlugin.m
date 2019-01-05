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
        NSMutableArray<NSString *> *data = [@[] mutableCopy];
        for (NSUInteger i = 0; i < [frameArray count]; ++i) {
            [data addObject:frameArray[i].description];
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

        NSString *cause = exception[@"cause"] ? exception[@"cause"] : @"Flutter Error";
        NSString *message = exception[@"message"] ? exception[@"message"] : @"";
        NSArray<NSDictionary *> *traces = exception[@"traces"];
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

- (NSArray<CLSStackFrame *> *)buildStackTrace:(NSArray<NSDictionary *> *)traces {
    NSMutableArray<CLSStackFrame *> *stacks = [[NSMutableArray alloc] init];

    for (NSUInteger i = 0; i < traces.count; i++) {
        NSDictionary *trace = traces[i];
        NSString *className = trace[@"class"] ? trace[@"class"] : @"";
        NSString *methodName = trace[@"method"] ? trace[@"class"] : @"";
        NSString *libraryName = trace[@"library"] ? trace[@"class"] : @"";

        CLSStackFrame *frame = [[CLSStackFrame alloc] init];
        [frame setSymbol:[NSString stringWithFormat:@"%@.%@", className, methodName]];
        [frame setLibrary:className];
        [frame setRawSymbol:className];
        [frame setFileName:libraryName];

        if (trace[@"line"]) {
            [frame setLineNumber:(uint32_t) trace[@"line"]];
        }

        [stacks addObject:frame];
    }

    return stacks;
}

- (void)crash:(NSString *)cause reason:(NSString *)reason frames:(NSArray<CLSStackFrame *> *)frameArray {

    CLSLog(@"%@ %@", cause, reason);

    for (NSUInteger i = 0; i < [frameArray count]; ++i) {
        CLSLog(@"%@", frameArray[i].description);
    }

    FlutterException *ex = [[FlutterException alloc] initWithName:cause reason:reason frameArray:frameArray];

    [ex raise];
}

@end
