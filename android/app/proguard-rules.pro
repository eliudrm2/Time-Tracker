## Flutter
-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.FlutterInjector { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-dontwarn io.flutter.embedding.**

## Plugins
-dontwarn androidx.core.view.ViewCompat
-dontwarn androidx.core.graphics.drawable.DrawableCompat
-keep class com.timetracker.app.flutter_app.** { *; }
