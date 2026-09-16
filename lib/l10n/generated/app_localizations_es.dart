// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class LEs extends L {
  LEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Entrenamiento de Hoy';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get exerciseNameHint => 'Nombre del ejercicio';

  @override
  String get repeatPrevious => 'Igual que antes';

  @override
  String get addSet => 'Añadir Serie';

  @override
  String get numberKeypad => 'Teclado Numérico';

  @override
  String setOrdinal(int n) {
    return 'Serie $n';
  }

  @override
  String repsCount(int n) {
    return '$n reps';
  }

  @override
  String get allNotes => 'Todos los registros';

  @override
  String noteCount(int n) {
    return '$n registros';
  }

  @override
  String get previous7Days => 'Últimos 7 días';

  @override
  String get previous30Days => 'Últimos 30 días';

  @override
  String monthLabel(int m) {
    return '$m';
  }

  @override
  String get search => 'Buscar';

  @override
  String get newNote => 'Nuevo registro';

  @override
  String get untitledNote => 'Nuevo registro';

  @override
  String get noNotesYet => 'Aún no hay registros';

  @override
  String get noSearchResults => 'Sin resultados';

  @override
  String dayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.yMd(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get finishExercise => 'Listo';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String deleteExerciseTitle(String name) {
    return 'Eliminar $name';
  }

  @override
  String deleteExerciseBody(int n) {
    return 'Se eliminarán $n series. No se puede deshacer.';
  }

  @override
  String get deleteExerciseEmptyBody => 'Se eliminará este ejercicio.';

  @override
  String get next => 'Siguiente';

  @override
  String stepSizeTitle(String unit) {
    return 'Paso de $unit';
  }

  @override
  String kcal(int n) {
    return '$n kcal';
  }

  @override
  String weekdayLabel(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.EEEE(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get noteHint => 'Nota para esta serie';

  @override
  String get activeEnergy => 'Energía activa';

  @override
  String get energyUnavailable => 'Sin datos';

  @override
  String get energySource => 'Salud · Durante este registro';

  @override
  String get doneEditing => 'Listo';

  @override
  String get setInputHint => 'Peso  Reps';

  @override
  String get setRequired => 'Primero introduce una serie, p. ej. 60 12.';

  @override
  String get aiTitle => 'Configurar con una frase';

  @override
  String get aiReady => 'Disponible';

  @override
  String get aiChecking => 'Comprobando';

  @override
  String get aiSetupNeeded => 'Requiere configuración';

  @override
  String get aiPreparing => 'Preparando';

  @override
  String get aiUnavailable => 'Entrada manual';

  @override
  String get aiReadyBody =>
      'Escribe «press banca 80kg, llegar a 100 repeticiones» y pulsa Enter. El peso y las metas se configuran automáticamente. El texto se procesa en el dispositivo.';

  @override
  String get aiDisabledBody =>
      'Abre Ajustes → Apple Intelligence y Siri y activa Apple Intelligence. Vuelve cuando el modelo esté listo; se comprobará automáticamente.';

  @override
  String get aiOsBody =>
      'Se requiere iOS 26 o posterior y un dispositivo compatible con Apple Intelligence. Comprueba Ajustes → General → Actualización de software.';

  @override
  String get aiDeviceBody =>
      'Este dispositivo no es compatible con Apple Intelligence. La configuración con una frase no está disponible.';

  @override
  String get aiPreparingBody =>
      'El dispositivo está preparando el modelo de IA. Conéctate a Wi-Fi y compruébalo más tarde.';

  @override
  String get aiDownloadBody =>
      'Puedes descargar el modelo de IA. Se recomienda Wi-Fi; la descarga requiere tiempo y espacio. Después, el texto se procesa en el dispositivo.';

  @override
  String get aiLanguageBody =>
      'El modelo de IA no admite el idioma de la app. Cambia a un idioma compatible y vuelve a comprobarlo.';

  @override
  String get aiPlatformBody =>
      'La IA local no está disponible en este entorno. Usa la app en un iPhone o Android compatible.';

  @override
  String get aiUnavailableBody =>
      'La IA no está disponible ahora. Depende del dispositivo, el sistema y su servicio de IA. Si acabas de configurar el dispositivo, conéctate a internet y vuelve a comprobarlo.';

  @override
  String get aiManualBody =>
      'Puedes seguir registrando entrenamientos. Elige un ejercicio e introduce «80 20» o solo las repeticiones por serie.';

  @override
  String get aiPrepare => 'Preparar modelo';

  @override
  String get aiRetry => 'Comprobar de nuevo';

  @override
  String get aiWorking => 'Configurando ejercicio…';

  @override
  String get aiFailure =>
      'No se pudo interpretar la entrada. Edítala o úsala como nombre del ejercicio.';

  @override
  String get aiUseName => 'Usar como nombre';

  @override
  String goalProgress(int done, int goal) {
    return '$done/$goal reps';
  }

  @override
  String repsPerSetLabel(int n) {
    return '$n reps por serie';
  }

  @override
  String setProgress(int done, int goal) {
    return '$done/$goal series';
  }

  @override
  String get repsInputHint => 'Reps';

  @override
  String get setupTitle => 'Configurar ejercicio';

  @override
  String get setupWeight => 'Peso predeterminado';

  @override
  String get setupTotalReps => 'Meta total de reps';

  @override
  String get setupSetReps => 'Reps por serie';

  @override
  String get setupTotalSets => 'Meta de series';

  @override
  String get moveExercise => 'Mover ejercicio';

  @override
  String get weightUnitSetting => 'Unidad de peso predeterminada';

  @override
  String get weightUnitHelp =>
      'Se usa en ejercicios nuevos. Los pesos y unidades registrados no cambian.';

  @override
  String answerDays(int n) {
    return '$n días registrados';
  }

  @override
  String answerWeeks(int n) {
    return '$n semanas';
  }

  @override
  String answerFrequency(String n) {
    return '$n/semana';
  }

  @override
  String answerPeak(String value) {
    return 'Máximo $value';
  }

  @override
  String answerNoPeak(int n) {
    return 'Máximo sin cambios durante $n semanas';
  }

  @override
  String answerSince(String date) {
    return 'Desde $date';
  }

  @override
  String answerAgo(int n) {
    return 'Hace $n días';
  }

  @override
  String answerPerSet(String value) {
    return '$value por serie';
  }

  @override
  String answerChange(String weeks, String value) {
    return '$weeks · $value';
  }

  @override
  String answerChart(String name, int n) {
    return '$name · $n días registrados';
  }

  @override
  String answerWeightReps(String value, String reps) {
    return '$value × $reps';
  }

  @override
  String answerSets(int n) {
    return '$n series';
  }

  @override
  String timingBpm(int n) {
    return '$n BPM';
  }

  @override
  String timingProtocol(int work, int rest, int rounds) {
    return 'Tabata ${work}s / ${rest}s · $rounds rondas';
  }

  @override
  String timingRound(int n, int total) {
    return 'Ronda $n/$total';
  }

  @override
  String timingRoundDone(int n) {
    return 'Ronda $n completada';
  }

  @override
  String get timingMetronome => 'Metrónomo';

  @override
  String get timingReady => 'Preparación';

  @override
  String get timingWork => 'Ejercicio';

  @override
  String get timingRest => 'Descanso';

  @override
  String get timingComplete => 'Completado';

  @override
  String get timingStart => 'Iniciar';

  @override
  String get timingPause => 'Pausar';

  @override
  String get timingReset => 'Reiniciar';

  @override
  String get timingInvalid =>
      'Usa 10–120 BPM, 1–600 s de trabajo y descanso, y 1–99 rondas.';

  @override
  String get timingSoundFailed =>
      'No se puede reproducir sonido. El temporizador sigue activo.';

  @override
  String get queryTitle => 'Pregunta a tus registros';

  @override
  String get queryReadyBody =>
      'Pregunta “¿Cuál es mi máximo en sentadilla?”, “¿Cuántas flexiones hice el mes pasado?” o “¿Mejoró mi press este mes?”. La IA del dispositivo interpreta la pregunta; los cálculos usan tus registros.';

  @override
  String get queryManualBody =>
      'Las preguntas en lenguaje natural requieren la IA del dispositivo. La búsqueda de ejercicios y notas siempre está disponible.';

  @override
  String get queryWorking => 'Interpretando tu pregunta…';

  @override
  String get queryFailed =>
      'No se pudo obtener la respuesta. Inténtalo de nuevo.';

  @override
  String get queryUnsupported =>
      'Haz una pregunta sobre tus registros de entrenamiento.';

  @override
  String get queryOffline => 'Las preguntas necesitan conexión.';

  @override
  String get queryNoData =>
      'Faltan registros completados o mediciones necesarias. Revisa los registros originales.';

  @override
  String queryPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get queryAllTime => 'Todo el período';

  @override
  String get queryPresent => 'Actualidad';

  @override
  String get queryRepUnit => 'reps';

  @override
  String get querySetUnit => 'series';

  @override
  String get queryDayUnit => 'días';

  @override
  String get queryAverage => 'Peso medio por serie';

  @override
  String get queryMissingData =>
      'Tus registros no contienen el ejercicio o medición necesarios.';

  @override
  String get queryAmbiguous => 'Aclara a qué ejercicio y registro te refieres.';

  @override
  String queryRank(int n) {
    return 'Puesto $n';
  }

  @override
  String timingWorkSeconds(int n) {
    return 'Trabajo ${n}s';
  }

  @override
  String timingRestSeconds(int n) {
    return 'Descanso ${n}s';
  }

  @override
  String timingRounds(int n) {
    return '$n rondas';
  }

  @override
  String timingBeat(String count) {
    return 'Pulso $count';
  }

  @override
  String timingHeart(int bpm, int target) {
    return '♥ $bpm → $target';
  }

  @override
  String get accountSignIn => 'Inicia sesión y respalda';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get planMonthly => 'Mensual';

  @override
  String get planLifetime => 'De por vida';

  @override
  String get planActive => 'Activo';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get quotaSpent => 'Has usado las preguntas de este mes.';

  @override
  String gymMember(String gym, String trainer) {
    return '$gym · $trainer';
  }

  @override
  String gymOnly(String gym) {
    return '$gym';
  }

  @override
  String routineFromTrainer(String gym) {
    return 'De $gym';
  }

  @override
  String get partnerInvite => 'Entrenar juntos';

  @override
  String get partnerCode => 'Dile este código a tu compañero';

  @override
  String get partnerEnter => 'Introducir código';

  @override
  String partnerJoined(String name) {
    return 'Registrando con $name';
  }

  @override
  String get partnerFailed => 'Ese código es incorrecto o caducó.';

  @override
  String bookingNext(String trainer, String when) {
    return '$trainer · $when';
  }

  @override
  String get bookingNew => 'Reservar sesión';

  @override
  String get bookingNone => 'No hay horas libres ese día.';

  @override
  String get bookingCancel => 'Cancelar reserva';

  @override
  String get countAloud => 'Contar los pulsos en voz alta';

  @override
  String get metricMax => 'Máximo';

  @override
  String get metricTrend => 'Tendencia';

  @override
  String get metricLast => 'Última';

  @override
  String get metricSessions => 'Días';

  @override
  String get metricVolume => 'Volumen';

  @override
  String get metricReps => 'Reps totales';

  @override
  String get metricSets => 'Series';

  @override
  String get metricAverage => 'Promedio';

  @override
  String get readAsConfirm => 'Entendido como';

  @override
  String get confirmYes => 'Sí';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get reviewNumbers =>
      'Revisa los números y las condiciones antes de aplicar.';

  @override
  String get querySourceOnly => 'Ver registros originales';

  @override
  String get queryCompareOrder => 'Segundo período − primer período';

  @override
  String queryRankingLimit(int n) {
    return 'Primeros $n · descendente';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsRecording => 'Registro';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsGym => 'Tu gimnasio';

  @override
  String get settingsNoGym =>
      'Acerca tu teléfono a la pegatina del gimnasio para recibir la rutina de tu entrenador.';

  @override
  String get proTitle => 'Pregunta lo que quieras a tu registro';

  @override
  String get proBody =>
      'Pregunta “mi sentadilla más pesada” o “¿mejoré en press de banca?” y obtén respuestas calculadas desde tu registro.';

  @override
  String proFree(int n) {
    return 'Gratis: $n al mes';
  }

  @override
  String proPaid(int n) {
    return 'Con plan: $n al día';
  }

  @override
  String get proEverythingElseFree =>
      'Registrar, temporizadores, salud y funciones del gimnasio funcionan sin plan.';

  @override
  String get proOwned => 'Activo. Gracias.';

  @override
  String get proSignInFirst =>
      'El plan va ligado a una cuenta. Inicia sesión primero.';

  @override
  String get tagSignInNeeded => 'Inicia sesión para conectar con tu gimnasio.';

  @override
  String get tagJoinSent =>
      'Solicitud enviada. Podrás empezar en cuanto un entrenador la confirme.';

  @override
  String get tagJoinWaiting =>
      'Ya la has enviado. Un entrenador la está revisando.';

  @override
  String get tagJoinFailed =>
      'No se pudo enviar la solicitud. Acerca el teléfono otra vez en un momento.';

  @override
  String get bookingPending => 'Pendiente de aprobación';

  @override
  String get bookingWhichGym => '¿Qué gimnasio?';

  @override
  String get tagSignIn => 'Iniciar sesión';

  @override
  String get accountDelete => 'Eliminar cuenta';

  @override
  String get accountDeleteAsk =>
      'Esto no se puede deshacer. Tus rutinas, registros, bonos y reservas desaparecerán.';

  @override
  String get accountDeleteDo => 'Eliminar';

  @override
  String get accountDeleteFailed =>
      'No se pudo eliminar la cuenta. Inténtalo de nuevo en un momento.';

  @override
  String get ok => 'Aceptar';
}
