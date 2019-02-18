#import <Flutter/Flutter.h>

@class CLSStackFrame;

@interface FlutterException : NSException
@property(nonatomic, assign) NSArray <CLSStackFrame *> *frameArray;
@end

@interface FlutterCrashlyticsPlugin : NSObject <FlutterPlugin>
@property(nonatomic, assign) BOOL isFabricInitialized;
@end
