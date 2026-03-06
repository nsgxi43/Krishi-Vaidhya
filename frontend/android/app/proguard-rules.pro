# Flutter TFLite GPU delegate missing classes
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Keep TFLite classes
-keep class org.tensorflow.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
