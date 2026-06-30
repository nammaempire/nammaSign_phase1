# ProGuard / R8 keep rules for NammaSign release builds.
#
# The app (de)serializes Firestore data through generated json_serializable /
# freezed code (compile-time, no reflection), so R8 is safe. These rules are
# belt-and-suspenders to protect the few things that *do* rely on reflection
# or that we want readable in crash reports.

# ---- Flutter engine / embedding ----
# The Flutter Gradle plugin injects its own rules; keep these as insurance.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Firebase / Google Play services ----
# Firebase ships consumer ProGuard rules, but keep the public surface and
# silence warnings about optional transitive classes.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# If any POJO is ever handed directly to Firestore, keep its annotated
# members so reflection-based mapping still works after shrinking.
-keepclassmembers class * {
  @com.google.firebase.firestore.PropertyName <methods>;
  @com.google.firebase.firestore.PropertyName <fields>;
}

# ---- Crashlytics ----
# Preserve source file names + line numbers so crash reports stay readable,
# and keep exception types intact.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ---- General ----
# Annotations, generic signatures and inner-class metadata used by several
# libraries (gson-style mappers, kotlin reflect, etc.).
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
