# Keep the classes from the Google API client and HttpTransport
-keep class com.google.api.client.http.GenericUrl.** { *; }
-keep class com.google.api.client.http.HttpHeaders.** { *; }
-keep class com.google.api.client.http.HttpRequest.** { *; }
-keep class com.google.api.client.http.HttpRequestFactory.** { *; }
-keep class com.google.api.client.http.HttpResponse.** { *; }
-keep class com.google.api.client.http.HttpTransport.** { *; }
-keep class com.google.api.client.http.javanet.NetHttpTransport$Builder.** { *; }
-keep class com.google.api.client.http.javanet.NetHttpTransport.** { *; }

# Keep annotations (javax.annotation)
-keep @javax.annotation.Nullable class * { *; }
-keep @javax.annotation.concurrent.GuardedBy class * { *; }
-keep @javax.annotation.concurrent.ThreadSafe class * { *; }

# Keep Joda-Time classes
-keep class org.joda.convert.FromString.** { *; }
-keep class org.joda.convert.ToString.** { *; }

# Suppress warnings about these missing classes
-keep class com.google.api.client.http.GenericUrl.** { *; }
-keep class com.google.api.client.http.HttpHeaders.** { *; }
-keep class com.google.api.client.http.HttpRequest.** { *; }
-keep class com.google.api.client.http.HttpRequestFactory.** { *; }
-keep class com.google.api.client.http.HttpResponse.** { *; }
-keep class com.google.api.client.http.HttpTransport.** { *; }
-keep class com.google.api.client.http.javanet.NetHttpTransport$Builder.** { *; }
-keep class com.google.api.client.http.javanet.NetHttpTransport.** { *; }
-keep class javax.annotation.Nullable.** { *; }
-keep class javax.annotation.concurrent.GuardedBy.** { *; }

-dontwarn javax.annotation.concurrent.ThreadSafe
-dontwarn org.joda.convert.FromString
-dontwarn org.joda.convert.ToString
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy