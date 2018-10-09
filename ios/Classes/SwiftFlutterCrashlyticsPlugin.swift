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
        let channel = FlutterMethodChannel(name: "flutter_crashlytics", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterCrashlyticsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    var isFabricInitialized = false
    
    private func buildStackTrace(traces: Array<Dictionary<String, Any>>?) -> [CLSStackFrame] {
        var stacks = [CLSStackFrame]()
        
        traces?.forEach {trace in
            let className: String = trace["class"] as? String ?? ""
            let methodName: String = trace["method"] as? String ?? ""
            let libraryName: String = trace["library"] as? String ?? ""
            let frame = CLSStackFrame(symbol: "\(className).\(methodName)")
            frame.library = className
            frame.rawSymbol = className
            frame.fileName = libraryName
            if let ln = trace["line"] as? Int {
                frame.lineNumber = UInt32(ln)
            }
            stacks.append(frame)
        }
        return stacks
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "initialize" {
            Fabric.with([Crashlytics.self])
            isFabricInitialized = true
            result(nil)
        } else if(isFabricInitialized) {
            onInitialisedMethodCall(call, result: result)
        } else {
            // Should not result in an error. Otherwise Opt Out clients would need to handle errors
            result(nil)
        }
    }
    
    private func onInitialisedMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let crashlytics = Crashlytics.sharedInstance()
        
        switch call.method {
        case "reportCrash":
            let exception = (call.arguments as! Dictionary<String, Any>)
            let cause = exception["cause"] as? String
            let message = exception["message"] as? String
            let traces = exception["trace"] as? Array<Dictionary<String, Any>>
            let forceCrash = exception["forceCrash"] as? Bool ?? false
            let stacks = buildStackTrace(traces: traces)
            
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
