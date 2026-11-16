# ML Kit text recognition: the Flutter plugin references the Chinese/Japanese/Korean/Devanagari
# recognizers, which are separate optional artifacts. Cuanly only uses the Latin one.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
