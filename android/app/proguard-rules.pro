# Flutter ProGuard/R8 Rules - Optimizado para Play Store
# NavShock Studio - Time Tracker App
# Estas reglas previenen problemas de ofuscación en producción

# ============================================
# REGLAS CRÍTICAS PARA FLUTTER
# ============================================

# Mantener las anotaciones de Android
-keepattributes *Annotation*

# Mantener la información de firma para debugging
-keepattributes Signature

# Mantener información de excepciones para stack traces útiles
-keepattributes Exceptions

# Mantener información de línea de código para debugging
-keepattributes SourceFile,LineNumberTable

# Si mantienes los números de línea, ofuscar los nombres de archivo
-renamesourcefileattribute SourceFile

# ============================================
# FLUTTER ESPECÍFICO
# ============================================

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter WebView
-keep class com.google.android.apps.** { *; }

# ============================================
# DART/FLUTTER REFLECTION
# ============================================

# Mantener clases que usan reflexión
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ============================================
# FIREBASE (si se usa)
# ============================================

# Firebase Auth
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep interface com.google.firebase.** { *; }
-keep interface com.google.android.gms.** { *; }

# Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.Timestamp { *; }
-keep class com.google.firebase.firestore.GeoPoint { *; }
-keep class com.google.firebase.firestore.Blob { *; }
-keep class com.google.firebase.firestore.FieldPath { *; }
-keep class com.google.firebase.firestore.FieldValue { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Firebase Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.crashlytics.** { *; }
-dontwarn com.crashlytics.**

# ============================================
# SHARED PREFERENCES
# ============================================

-keep class androidx.preference.** { *; }
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$* { *; }

# ============================================
# GOOGLE MOBILE ADS (AdMob)
# ============================================

-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep interface com.google.android.gms.ads.** { *; }
-keep interface com.google.ads.** { *; }

# AdMob mediation
-keepattributes *Annotation*
-keep public class com.google.ads.mediation.** { *; }
-keep public class com.google.android.gms.ads.mediation.** { *; }

# ============================================
# ANDROIDX Y SUPPORT LIBRARIES
# ============================================

-keep class androidx.** { *; }
-keep class android.support.** { *; }
-keep interface androidx.** { *; }
-keep interface android.support.** { *; }

# AppCompat
-keep public class androidx.appcompat.widget.** { *; }
-keep public class androidx.appcompat.view.menu.** { *; }

# Material Components
-keep class com.google.android.material.** { *; }
-keep class androidx.material.** { *; }

# ============================================
# KOTLIN
# ============================================

-keep class kotlin.Metadata { *; }
-keep class kotlin.** { *; }
-keep class kotlin.jvm.functions.** { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ============================================
# OKHTTP (para networking)
# ============================================

-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ============================================
# GSON (para JSON)
# ============================================

-keepattributes Signature
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Prevenir ofuscación de modelos de datos
-keep class com.navshock.timetracker.models.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ============================================
# WEBVIEW
# ============================================

-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# ============================================
# NATIVE METHODS
# ============================================

-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================
# ENUMS
# ============================================

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================
# PARCELABLES Y SERIALIZABLES
# ============================================

-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================
# R CLASS
# ============================================

-keep class **.R$* {
    <fields>;
}

# ============================================
# GOOGLE PLAY CORE (Split Install)
# ============================================

-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ============================================
# WARNINGS ESPECÍFICOS A IGNORAR
# ============================================

-dontwarn android.content.pm.PackageManager$OnPermissionsChangedListener
-dontwarn com.google.android.gms.**
-dontwarn com.google.common.**
-dontwarn com.google.api.client.**
-dontwarn com.google.auto.value.**
-dontwarn javax.annotation.**
-dontwarn sun.misc.**

# ============================================
# OPTIMIZACIÓN Y OFUSCACIÓN
# ============================================

# No optimizar código (puede causar problemas con reflection)
-dontoptimize

# Mantener nombres de clases en stack traces
-keepattributes SourceFile,LineNumberTable

# Mantener clases de entrada de la aplicación
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# ============================================
# REGLAS ADICIONALES DE SEGURIDAD
# ============================================

# Remover logs en release (seguridad)
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
}

# Remover System.out en release
-assumenosideeffects class java.io.PrintStream {
    public void println(...);
    public void print(...);
}

# ============================================
# MANTENER CLASES PERSONALIZADAS
# ============================================

# Mantener todas las clases del paquete de la app
-keep class com.navshock.** { *; }
-keep interface com.navshock.** { *; }

# Fin del archivo ProGuard/R8