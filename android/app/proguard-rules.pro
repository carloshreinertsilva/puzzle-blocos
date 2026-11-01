# Classes do Kotlin que as bibliotecas JNI procuram pelo nome. Sem estas regras
# o R8 as renomeia nas versões de lançamento e o jogo não passa da abertura.
# https://github.com/flutter/flutter/issues/194649
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }

# O WorkManager (trazido pelo SDK do AdMob) cria o seu banco Room por
# reflexão ao abrir o app. Sem estas regras o R8 tira o construtor e o app
# fecha na hora: "Failed to create an instance of
# androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
