# flutter_crashlytics

Flutter plugin to enable Crashlytics reporting.

## Setup

### Android
To setup Crashlytics on Android side, you need to set under your manifest the Fabric ID like: 

```
 <meta-data
            android:name="io.fabric.ApiKey"
            android:value="YOUR_ID_HERE" />
```

You also need to change you build.gradle file like: 

```
buildscript {
    repositories {
        ...
        maven { url 'https://maven.fabric.io/public' }
    }

    dependencies {
        classpath 'io.fabric.tools:gradle:1.+'
        ...
    }
}
```

And apply the fabric plugin `apply plugin: 'io.fabric'` 

Nothing more.

### iOS
On iOS side your need to set your Fabric ID under your Info.plist like: 

```
<key>Fabric</key>
    <dict>
        <key>APIKey</key>
        <string>YOUR_ID_HERE</string>
        <key>Kits</key>
        <array>
            <dict>
                <key>KitInfo</key>
                <dict/>
                <key>KitName</key>
                <string>Crashlytics</string>
            </dict>
        </array>
    </dict>
```

Then on your Podfile add `use_frameworks!`

Don't forget to add your `Run Script` step on the build phases tab: 
![ios run script](https://github.com/kiwi-bop/flutter_crashlytics/raw/master/iosScript.jpg "ios run script") 

That's it :)

### Flutter 
All you need to do under your code is to let the plugin handle the Flutter crashes.

Under your `main` method, add:

```
FlutterError.onError = (FlutterErrorDetails details) async {
    await FlutterCrashlytics().onError(details, forceCrash: true);
  };
```

`forceCrash` allow you to have a real crash instead of the red screen, in that case the exception will tagged as fatal 

## API available
- Add log to crash reporting with `log(String msg, {int priority, String tag})`
- Add user info to crash reporting with `setUserInfo(String identifier, String email, String name)`
- Add general info to crash reporting with  `setInfo(String key, dyncamic value)`

## Limitation 
This plugin uses Crashlytics sdk to log manually dart crashes, all manual logged crashes are tagged as non fatal under Crashlytics, that's a limitation of the SDK.

You can bypass that limitation with the `forceCrash` parameter, instead of the red screen an actual crash will append, the crash will be tagged as Fatal.

On iOS fatal crash has there dart stacktrace under the `Logs` tab of Crashlytics, that's a limitation of iOS that prevent developers to set a custom stacktrace to an exception. 

## Contribution
We love contributions! Don't hesitate to open issues and make pull request to help improve this plugin 