#import "FlutterCrashlyticsPlugin.h"
#import <flutter_crashlytics/flutter_crashlytics-Swift.h>

@implementation FlutterCrashlyticsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterCrashlyticsPlugin registerWithRegistrar:registrar];
}
@end
