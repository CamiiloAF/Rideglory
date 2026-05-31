# ML Kit text recognition (OCR del SOAT): solo se empaqueta el script Latin.
# El plugin referencia los reconocedores de otros idiomas, que no se incluyen,
# así que R8 los ignora en lugar de fallar por clases ausentes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
