# Keep Flutter engine, FileProvider, and native MethodChannel host classes intact.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-keep class com.acuerdovecinal.acuerdo_vecinal.MainActivity { *; }
-dontwarn io.flutter.embedding.**
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
