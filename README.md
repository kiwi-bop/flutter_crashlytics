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

You also need to to change you build.gradle file like: 

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

That's it :)

### Flutter 
All you need to do under your code is to let the plugin handle the Flutter crashes.

Under your `main` method, add:

```
FlutterError.onError = (FlutterErrorDetails details) async {
    await FlutterCrashlytics().onError(details);
  };
```

### API available
- Add log to crash reporting with `log(String msg, {int priority, String tag})`
- Add user info to crash reporting with `setUserInfo(String identifier, String email, String name)`
- Add general info to crash reporting with  `setInfo(String key, dyncamic value)`

### Limitation 
This plugin use Crashlytics sdk to log manually dart crashed, all manual logged crashes are tagged as non fatal under crashlytics, that's a limitation of the SDK.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/developing-packages/#edit-plugin-package).
