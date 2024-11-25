# Keep Tink annotations and relevant classes
-keep class com.google.errorprone.annotations.** { *; }
-keep class javax.annotation.** { *; }

# Keep relevant Tink classes
-keep class com.google.crypto.tink.** { *; }

# Keep all classes related to the missing annotations
-keep class com.google.crypto.tink.* { *; }

# Keep classes related to Google API Client and HTTP
-keep class com.google.api.client.http.** { *; }

# Keep Joda-Time classes
-keep class org.joda.time.** { *; }
