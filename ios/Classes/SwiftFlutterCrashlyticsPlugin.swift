import Flutter
import UIKit
import Fabric
import Crashlytics

class FlutterCrash: Error {
    let localizedDescription: String
    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
    
public class SwiftFlutterCrashlyticsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_crashlytics", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterCrashlyticsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    Fabric.with([Crashlytics.self])
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let crashlytics = Crashlytics.sharedInstance()
    switch call.method {
    case "reportCrash":
        let exception = (call.arguments as! Dictionary<String, Any>)
        let cause = exception["cause"] as? String
        let message = exception["message"] as? String
        let traces = exception["trace"] as? Array<Array<Any>>
        var stacks = [CLSStackFrame]()
        
        traces?.forEach {trace in
            let frame = CLSStackFrame(symbol: "\(trace[0]).\(trace[1])")
            frame.library = trace[1] as? String ?? ""
            frame.rawSymbol = trace[1] as? String ?? ""
            frame.fileName = trace[2] as? String ?? ""
            if let ln = trace[3] as? Int {
                frame.lineNumber = UInt32(ln)
            }
            stacks.append(frame)
        }
        crashlytics.recordCustomExceptionName(cause ?? "Flutter Error", reason: message, frameArray: stacks)
        result(nil)
        break
    case "log":
        if (call.arguments is String) {
            CLSLogv("%@", getVaList([call.arguments as! String]))
        } else {
            let info = call.arguments as! Array<Any>
            CLSLogv("%d: %@ %@", getVaList([info[0] as! Int, info[1] as! String, info[2] as! String]))
        }
        result(nil)
        break
    case "setInfo":
        let info = call.arguments as! Dictionary<String, Any>
        crashlytics.setValue(info["value"], forKey: info["key"] as! String)
        result(nil)
        break
    case "setUserInfo":
        let info = call.arguments as! Dictionary<String, String>
        crashlytics.setUserName(info["name"])
        crashlytics.setUserEmail(info["email"])
        crashlytics.setUserIdentifier(info["id"])
        result(nil)
        break
    default:
        result(FlutterMethodNotImplemented)
    }
  }
}
