# ProGuard / R8 keep rules for Reset95 release builds.
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

# =====================================================================
# Added for production R8 re-enable (Reset95)
# =====================================================================

# ---- Play Core / deferred components (THE common Flutter R8 crash) ----
# Flutter's embedding references these split-install classes; without keeps
# R8 fails with "Missing classes" or the release app crashes on launch.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ---- Play Integrity ----
-dontwarn com.google.android.play.integrity.**
-keep class com.google.android.play.integrity.** { *; }

# ---- Firebase App Check ----
-dontwarn com.google.firebase.appcheck.**
-keep class com.google.firebase.appcheck.** { *; }

# ---- video_player (ExoPlayer / media3) ----
-dontwarn com.google.android.exoplayer2.**
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn androidx.media3.**
-keep class androidx.media3.** { *; }

# ---- Kotlin runtime / metadata ----
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations,AnnotationDefault

# ---- Razorpay (in-app payments) ----
# The Checkout SDK uses reflection + annotations and ships proguard rules,
# but keep these explicitly so R8 (when re-enabled) can't strip the entry
# points or the Google Pay / analytics classes it references optionally.
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}
-keep class com.razorpay.** { *; }
-keep interface com.razorpay.** { *; }
-dontwarn com.razorpay.**
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
# Razorpay optionally references these — safe to ignore if absent.
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-dontwarn com.google.android.gms.wallet.**

# ---- Native (JNI) + enums used by plugins ----
-keepclasseswithmembernames class * { native <methods>; }
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
