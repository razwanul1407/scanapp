# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Google Play Core (required for Flutter deferred components)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep Cunning Document Scanner
-keep class biz.cunning.** { *; }

# Keep PDF generation
-keep class com.itextpdf.** { *; }

# Keep SQLite
-keep class org.sqlite.** { *; }
-keep class io.flutter.plugins.sqflite.** { *; }

# Keep share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
