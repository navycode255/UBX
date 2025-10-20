# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Flutter secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep biometric authentication
-keep class androidx.biometric.** { *; }

# Keep local authentication
-keep class androidx.fingerprint.** { *; }

# Keep image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep HTTP client
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes that have @Keep annotation
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Keep all classes in the main package
-keep class com.secureapp.ubx.** { *; }

# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep all enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep all classes that are referenced by reflection
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Keep secure storage classes
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep biometric authentication classes
-keep class androidx.biometric.** { *; }
-keep class androidx.fingerprint.** { *; }

# Keep local authentication classes
-keep class androidx.localauth.** { *; }

# Keep image picker classes
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep path provider classes
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep URL launcher classes
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep shared preferences
-keep class android.content.SharedPreferences { *; }

# Keep SQLite classes
-keep class android.database.sqlite.** { *; }

# Keep JSON classes
-keep class org.json.** { *; }

# Keep Gson classes if used
-keep class com.google.gson.** { *; }

# Keep Retrofit classes if used
-keep class retrofit2.** { *; }

# Keep OkHttp classes if used
-keep class okhttp3.** { *; }

# Obfuscation settings
-obfuscationdictionary obfuscation-dictionary.txt
-classobfuscationdictionary class-obfuscation-dictionary.txt
-packageobfuscationdictionary package-obfuscation-dictionary.txt

# Keep line numbers for debugging (remove in final release)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

