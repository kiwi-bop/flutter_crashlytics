#import <Flutter/Flutter.h>

@class CLSStackFrame;

@interface FlutterException : NSException
@property(nonatomic, assign) NSArray <CLSStackFrame *> *frameArray;
@property(readonly, copy) NSArray<NSString *> *callStackSymbols;
@end

@interface FlutterCrashlyticsPlugin : NSObject <FlutterPlugin>
@property(nonatomic, assign) BOOL isFabricInitialized;
@end