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
-keep class com.google.android.gms.internal.ads.** { *; }
-keep class com.google.android.gms.ads.mediation.** { *; }

## User Messaging Platform (UMP / consent)
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.ump.**

## Keep generic signatures used by reflection-heavy libs
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
