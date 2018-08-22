import Flutter
import UIKit
import Fabric
import Crashlytics

class FlutterCrash: Error {
    
}

func CLS_LOG_SWIFT(msg: String, _ args:[CVarArg] = [])
{
    #if SWIFT_DEBUG
    CLSNSLogv(msg, getVaList(args))
    #else
    CLSLogv(msg, getVaList(args))
    #endif
}

public class SwiftFlutterCrashlyticsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    Fabric.with([Crashlytics.self])
    let channel = FlutterMethodChannel(name: "flutter_crashlytics", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterCrashlyticsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let crashlytics = Crashlytics.sharedInstance()
    
    switch call.method {
    case "reportCrash":
        let exception = (call.arguments as! Dictionary<String, Any>)
        let cause = exception["cause"] as? String
        let message = exception["message"] as? String
        let traces = exception["trace"] as? Array<Array<Any>>
        let forceCrash = exception["forceCrash"] as? Bool ?? false
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
        if(forceCrash) {
            try! crash(cause ?? "Flutter Error", reason: message ?? "", frameArray: stacks)
        }
        else {
            crashlytics.recordCustomExceptionName(cause ?? "Flutter Error", reason: message, frameArray: stacks)
        }
        result(nil)
        break
    case "log":
        if (call.arguments is String) {
            CLS_LOG_SWIFT(msg: "%@", [call.arguments as! String])
        } else {
            let info = call.arguments as! Array<Any>
            CLS_LOG_SWIFT(msg: "%d: %@ %@", [info[0] as! Int, info[1] as! String, info[2] as! String])
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
    
    func crash(_ cause: String, reason: String, frameArray: Array<CLSStackFrame>) throws{
        CLS_LOG_SWIFT(msg: "%@ %@", [cause, reason])
        frameArray.forEach { (line) in
            CLS_LOG_SWIFT(msg: "%@", [line.description])
        }
        let ex = FlutterException(name: NSExceptionName(rawValue: cause), reason: reason, frameArray: frameArray)
        
        ex.raise()
        //throw ex
    }
}

class FlutterException: NSException, Error {
    let frameArray: Array<CLSStackFrame>
    init(name aName: NSExceptionName, reason aReason: String?, frameArray: Array<CLSStackFrame>) {
        self.frameArray = frameArray
        super.init(name: aName, reason: aReason, userInfo: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        frameArray = []
        super.init(coder: aDecoder)
    }
    
    
    
    override var callStackSymbols: [String] {
        return frameArray.map({ (frame) -> String in
            return "\(frame.description)"
        })
    }
    
}
