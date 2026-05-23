# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dart/Flutter
-keep class com.google.firebase.** { *; }
-dontwarn io.flutter.embedding.**

# SQLite / Drift
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# PocketBase / HTTP
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn okhttp3.**
-dontwarn okio.**

# Riverpod
-keep class dev.rikka.tools.refine.** { *; }

# General
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception