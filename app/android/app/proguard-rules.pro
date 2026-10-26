# Flutter Gradle plugin also applies flutter_proguard_rules.pro on release
# (keeps FlutterPlugin implementors). Rules below cover plugins R8 has broken.

# Google Mobile Ads + UMP (consent). AARs ship consumer rules; these keep the
# classes the SDK and the Flutter plugin reach by reflection.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-keep class com.google.android.gms.internal.consent_sdk.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.ump.**
-dontwarn com.google.android.gms.internal.consent_sdk.**

# Play services annotation / measurement used by AdMob.
-keep class com.google.android.gms.common.internal.** { *; }
-dontwarn com.google.android.gms.**

# WorkManager / Room (pulled in by google_mobile_ads).
# R8 full mode stripped androidx.work.impl.WorkDatabase_Impl and crashed at launch.
-keep class androidx.work.** { *; }
-keep interface androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger
-keep public class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class *
-keepclassmembers class * extends androidx.room.RoomDatabase {
    public static ** getRequiredConverters();
}
-dontwarn androidx.work.**
-dontwarn androidx.room.**
-dontwarn androidx.sqlite.**

# Flutter plugins referenced from the generated registrant.
-keep class io.flutter.plugins.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-dontwarn io.flutter.plugins.**
-dontwarn dev.fluttercommunity.plus.**

-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
