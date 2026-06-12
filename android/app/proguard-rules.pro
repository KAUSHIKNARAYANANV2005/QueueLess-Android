# ── Flutter wrapper ──────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# ── Firebase ─────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# ── Razorpay ─────────────────────────────────────────────────────────────────
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keep class com.razorpay.** { *; }
-keep public class net.one97.paytm.** { *; }
-optimizations !method/inlining/*
-keepattributes Signature, InnerClasses
-keepattributes EnclosingMethod

# ── Google Maps ──────────────────────────────────────────────────────────────
-keep class com.google.maps.** { *; }
-keep class io.flutter.plugins.googlemaps.** { *; }

# ── Geolocator ───────────────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ── Generic Kotlin / Coroutines ──────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile, LineNumberTable

# ── Gson / JSON (used by Razorpay + Firebase) ────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ── OkHttp (networking) ───────────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ── App-specific models ───────────────────────────────────────────────────────
-keep class com.queueless.** { *; }
