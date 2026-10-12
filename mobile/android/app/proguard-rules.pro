## Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-keep class io.flutter.embedding.** { *; }

## flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

## Google Mobile Ads / Play Services
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.common.** { *; }

## Keep generic signatures used by reflection-heavy libs
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
