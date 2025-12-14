# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ✅ Just Audio
-keep class com.ryanheise.just_audio.** { *; }
-keep interface com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**

# ✅ Audio Service
-keep class com.ryanheise.audioservice.** { *; }
-keep interface com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**

# ✅ ExoPlayer (Just Audio ichida ishlatiladi)
-keep class com.google.android.exoplayer2.** { *; }
-keep interface com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# ✅ Media Session
-keep class androidx.media.** { *; }
-keep interface androidx.media.** { *; }
-dontwarn androidx.media.**

# ✅ Media3 (agar ishlatilsa)
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-dontwarn androidx.media3.**

# ✅ OkHttp (audio yuklash uchun)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ✅ Gson (agar JSON parse qilsangiz)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# ✅ Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# ✅ Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ✅ Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

## ✅ Parcelable
#-keep class * implements android.os.Parcelable {
#    public static final android.os.Parcelable$Creator *;
#}

# ✅ Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# ✅ Crash logs uchun
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile