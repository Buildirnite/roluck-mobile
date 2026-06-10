# --- ML Kit ---
# El plugin de OCR referencia reconocedores de otros idiomas (chino, japonés,
# coreano, devanagari) que no incluimos como dependencia. Sin estas reglas R8
# falla en release. Solo silenciamos los avisos de esas clases opcionales.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Mantener las clases de ML Kit que usamos (OCR latino y segmentación de
# sujeto), a las que se accede por reflexión desde los plugins.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
