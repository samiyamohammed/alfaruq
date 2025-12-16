## Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## WorkManager (Critical for Background Tasks)
-keep class androidx.work.** { *; }
-keep class be.tramckrijte.workmanager.** { *; }
-keep public class * extends androidx.work.Worker
-keep public class * extends androidx.work.ListenableWorker

## Geolocator
-keep class com.baseflow.geolocator.** { *; }

## Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

## Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

## Prevent obfuscation of generic Dart entry points
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

## --- FIX FOR R8 BUILD ERRORS ---
# Ignore missing Play Core classes (used for deferred components)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**