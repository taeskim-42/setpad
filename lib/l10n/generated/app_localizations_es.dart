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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString kcal';
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
  String setsPerLineMax(int n) {
    return 'Hasta $n series por línea. Divídelo en varias líneas.';
  }

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
  String get aiFallbackQuota =>
      'Ya usaste la ayuda de hoy, así que se añadió tal como lo escribiste';

  @override
  String get aiFallbackOffline =>
      'Sin conexión, así que se añadió tal como lo escribiste. Añade la configuración desde el ⚙ de la tarjeta';

  @override
  String get aiFallbackServer =>
      'El servidor no respondió, así que se añadió tal como lo escribiste. Añade la configuración desde el ⚙ de la tarjeta';

  @override
  String get aiFallbackUnread =>
      'No encontré nada que configurar, así que se añadió tal como lo escribiste. Añade la configuración desde el ⚙ de la tarjeta';

  @override
  String get inputNameTooLong =>
      'Los nombres de ejercicio tienen hasta 120 caracteres — divídelo en líneas';

  @override
  String get inputTooLong =>
      'No se lee un texto de más de 600 caracteres — divídelo en líneas';

  @override
  String get setupAdd => 'Añadir configuración';

  @override
  String setupUnparsed(String words) {
    return 'No pasó a la configuración: $words — queda en el título';
  }

  @override
  String setupDropped(String numbers) {
    return 'Quité números que no están en tu texto: $numbers';
  }

  @override
  String get setupNameMissing => 'Escribe el nombre del ejercicio';

  @override
  String get setupNameTooLong => 'Hasta 120 caracteres';

  @override
  String get setupWeightInvalid => 'Escribe un número mayor que 0 y hasta 2000';

  @override
  String get setupCountInvalid =>
      'Escribe un número entero de 1 o más — deja rangos y tiempos en el título';

  @override
  String get setupRepsOnly => 'Solo repeticiones';

  @override
  String setupSplit(int count) {
    return 'Dividido en $count ejercicios';
  }

  @override
  String get setupMergeAll => 'Unir en uno';

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
  String get accountSignIn => 'Iniciar sesión';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get planMonthly => 'Mensual';

  @override
  String get planYearly => 'Anual';

  @override
  String planYearlyTrial(int days, String price) {
    return 'Prueba gratis de $days días y luego $price al año. Cancela al menos 24 horas antes de que termine la prueba y no se te cobrará.';
  }

  @override
  String planYearlyTrialPlates(int n) {
    return 'Durante la prueba gratis, los discos se recargan hasta $n. La recarga mensual empieza cuando empieza el cobro.';
  }

  @override
  String get planActive => 'Activo';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get subscriptionRenews =>
      'La suscripción se renueva automáticamente al mismo precio salvo que la canceles al menos 24 horas antes de que termine el periodo actual. Puedes cancelarla cuando quieras en la gestión de suscripciones de la tienda.';

  @override
  String get termsOfUse => 'Términos de uso (EULA)';

  @override
  String get inputQuotaSpent =>
      'Ya usaste la ayuda para anotar de hoy. Si lo escribes tú, se guarda igual.';

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
  String get metricE1rm => '1RM estimado';

  @override
  String get metricMaxReps => 'Máx. reps';

  @override
  String get metricLongest => 'Más largo';

  @override
  String get metricFirst => 'Primera';

  @override
  String get metricDaysSince => 'Días sin entrenar';

  @override
  String get metricDistance => 'Distancia total';

  @override
  String get metricDuration => 'Tiempo total';

  @override
  String get readAsConfirm => 'Entendido como';

  @override
  String get confirmYes => 'Sí';

  @override
  String readAsNote(String from, String to) {
    return '$from → $to';
  }

  @override
  String get queryByExercise => 'Por ejercicio';

  @override
  String get queryByDay => 'Por día';

  @override
  String get queryByWeek => 'Por semana (desde el lunes)';

  @override
  String get queryByMonth => 'Por mes';

  @override
  String get queryByWeekday => 'Por día de la semana';

  @override
  String get queryTotalSum => 'Total';

  @override
  String get queryTotalMean => 'Promedio';

  @override
  String queryDiff(String later, String earlier) {
    return 'Diferencia ($later − $earlier)';
  }

  @override
  String queryExclude(String names) {
    return 'Excepto $names';
  }

  @override
  String queryMemo(String terms) {
    return 'Nota: $terms';
  }

  @override
  String queryLastSessions(int n) {
    return 'Últimas $n sesiones';
  }

  @override
  String queryBottomLimit(int n) {
    return 'Últimos $n · ascendente';
  }

  @override
  String queryOutOfScope(String names) {
    return 'Excluido (sin valores para esta medida): $names';
  }

  @override
  String queryMissingFor(String names) {
    return 'Sin calcular (series con valores faltantes): $names';
  }

  @override
  String get queryE1rmRule =>
      '1RM est. = peso × (1 + reps ÷ 30), solo series de 1–10 reps';

  @override
  String queryMore(int n) {
    return '$n más';
  }

  @override
  String queryRankingLimit(int n) {
    return 'Primeros $n · descendente';
  }

  @override
  String get queryCompareChip => 'Comparar';

  @override
  String get queryNoRecord => 'Sin registros';

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
  String get proTitle => 'Pro';

  @override
  String get proBody =>
      'Las preguntas sobre tu registro usan discos: normalmente uno por pregunta, y solo lo que la respuesta usó de verdad. La ayuda para anotar entrenos y comidas no usa discos.';

  @override
  String proFree(int n, int sets) {
    return 'Gratis: ayuda para anotar $n veces al día · 1 disco cada día que completes $sets series';
  }

  @override
  String proPaid(int n, int input) {
    return 'Pro: discos recargados hasta $n cada mes · ayuda para anotar $input veces al día';
  }

  @override
  String get proEverythingElseFree =>
      'El registro, los temporizadores, los avisos en la muñeca, entrenar juntos y los gimnasios funcionan sin Pro.';

  @override
  String get proOwned => 'Activo. Gracias.';

  @override
  String get proSignInFirst =>
      'El plan va ligado a una cuenta. Inicia sesión primero.';

  @override
  String platesBalance(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Te quedan $nString discos',
      one: 'Te queda 1 disco',
    );
    return '$_temp0';
  }

  @override
  String platesSpent(num spent, num balance) {
    final intl.NumberFormat spentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spentString = spentNumberFormat.format(spent);
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    String _temp0 = intl.Intl.pluralLogic(
      spent,
      locale: localeName,
      other: '$spentString discos',
      one: '1 disco',
    );
    String _temp1 = intl.Intl.pluralLogic(
      balance,
      locale: localeName,
      other: 'quedan $balanceString',
      one: 'queda 1',
    );
    return 'Usaste $_temp0 · $_temp1';
  }

  @override
  String noPlates(int sets) {
    return 'No tienes discos suficientes. Recibes 1 cada día que completas $sets series.';
  }

  @override
  String noPlatesSignIn(int n) {
    return 'Inicia sesión · las cuentas nuevas reciben $n discos';
  }

  @override
  String platesGetPro(int n) {
    return 'Ver Pro · $n al mes';
  }

  @override
  String get purchaseNotConfirmed =>
      'No pudimos confirmar la compra. Si se te cobró, toca «Restaurar compras» en un momento.';

  @override
  String get purchaseOtherAccount =>
      'Esta compra está vinculada a otra cuenta. Inicia sesión con esa cuenta.';

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
  String get signInFailed =>
      'No se pudo iniciar sesión. Inténtalo de nuevo en un momento.';

  @override
  String get bookingTitle => 'Reserva PT';

  @override
  String get bookingConfirmed => 'Confirmada';

  @override
  String bookingRemaining(int n) {
    return 'Quedan $n';
  }

  @override
  String get bookingNoPass => 'No tienes bono de PT. Pregunta a tu entrenador.';

  @override
  String bookingNoHours(String trainer) {
    return '$trainer aún no ha abierto horarios.';
  }

  @override
  String get bookingPick => 'Elige una hora';

  @override
  String bookingWith(String trainer, int minutes) {
    return '$trainer · $minutes min';
  }

  @override
  String get bookingSent =>
      'Solicitada. Se confirma cuando tu entrenador la apruebe.';

  @override
  String get bookingUpcoming => 'Próximas';

  @override
  String get bookingClosedDay => 'No disponible este día.';

  @override
  String get bookingCancelAsk => '¿Cancelar esta reserva?';

  @override
  String get ok => 'Aceptar';

  @override
  String get mealPhoto => 'Foto de comida';

  @override
  String get mealAdd => 'Registrar comida';

  @override
  String get mealWrite => 'Escribirlo';

  @override
  String get mealTypeHint =>
      'También puedes escribir la comida directamente en la línea del ejercicio';

  @override
  String get mealCamera => 'Cámara';

  @override
  String get mealGallery => 'De la galería';

  @override
  String get mealEstimating => 'Estimando calorías…';

  @override
  String mealIntake(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Ingesta ≈ $nString kcal';
  }

  @override
  String get mealFailed =>
      'No se pudieron estimar las calorías de esa foto. Prueba otra.';

  @override
  String get mealEstimateNote => 'Estimado a partir de la foto';

  @override
  String mealServingsOption(String n) {
    return '$n porción(es)';
  }

  @override
  String get fitAll => 'Entrenamiento de hoy';

  @override
  String sameDayToday(String time) {
    return 'Otro registro de hoy, $time';
  }

  @override
  String sameDayOn(String date, String time) {
    return 'Otro registro del $date, $time';
  }

  @override
  String get mealText => 'Escribir comida';

  @override
  String get mealTextHint => '¿Qué comiste? p. ej. 2 plátanos, leche 200ml';

  @override
  String kcalApprox(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '≈ $nString kcal';
  }

  @override
  String get mealKcalUnknown => 'kcal desconocidas';

  @override
  String mealIntakePartial(int n, int m) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Ingesta $nString kcal + $m sin kcal conocidas';
  }

  @override
  String get mealAmountAsk => '¿Cuánto comiste?';

  @override
  String get mealBasis => 'Base';

  @override
  String get mealEaten => 'Cantidad comida';

  @override
  String get mealUnitServing => 'porciones';

  @override
  String get mealUnitPackage => 'paquete entero';

  @override
  String get mealUnitPhoto => 'comida de la foto';

  @override
  String get mealWhole => 'Todo';

  @override
  String get mealHalf => 'La mitad';

  @override
  String get mealPhotoWholeNote =>
      'Es una estimación de todo lo que se ve en la foto. Elige cuánto comiste.';

  @override
  String get mealTextUnknown =>
      'No se pudieron estimar las calorías: no se reconoció el alimento. Toca la comida para añadir un nombre o una cantidad y se estimará de nuevo.';

  @override
  String get mealTextOffline =>
      'No se pudieron estimar las calorías: no hay conexión. Toca la comida y pulsa Intro para estimar de nuevo.';

  @override
  String get mealTextTooLong =>
      'Las notas de comida de más de 500 caracteres no se estiman. Toca la comida y divídela para obtener una estimación.';

  @override
  String queryTooLong(int max) {
    return 'Las preguntas pueden tener hasta $max caracteres. Acórtala, por favor.';
  }

  @override
  String get queryPressEnter =>
      'Pulsa Intro para preguntar sobre tus registros.';

  @override
  String get mealRetry => 'Estimar de nuevo';

  @override
  String kcalAtLeast(int n) {
    return '≥ $n kcal';
  }

  @override
  String mealTextPartial(int n) {
    return 'Solo se cuentan las $n kcal que escribiste; las calorías de los demás alimentos se desconocen.';
  }

  @override
  String mealTextBelowTyped(int n) {
    return 'La estimación salió por debajo de las $n kcal que escribiste, así que no se usó. Solo se cuentan tus $n kcal.';
  }

  @override
  String queryLimit(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'exercises':
          'Se pueden consultar hasta 8 ejercicios a la vez. Pregunta por partes.',
      'measures':
          'Se pueden contar hasta 4 cosas a la vez. Pregunta por partes.',
      'ranking': 'La clasificación muestra hasta 20. Pide 20 o menos.',
      'sessions':
          '\'Las últimas N sesiones\' llega hasta 100. Para más, pregunta por periodo, p. ej. este año.',
      'days':
          '\'Los últimos N días\' llega hasta 3660 días (unos 10 años). Para más, pregunta por todo el historial.',
      'compare':
          'Se pueden comparar hasta 6 cosas a la vez. Pregunta por partes.',
      'compareGrouped':
          'Una comparación no puede agruparse además por ejercicio, día, semana, mes o día de la semana en una sola pregunta. Pregunta por una de las dos.',
      'groupedMeasure':
          'Al comparar varios rangos agrupados por día, semana, mes o día de la semana solo se puede contar una cosa, y la tendencia, la última vez, la primera vez y los días desde la última no se agrupan.',
      'ordering':
          'Las clasificaciones, totales y promedios necesitan un agrupamiento, como por ejercicio o por semana.',
      'datesTotal':
          'Las fechas de la última y la primera vez no se pueden sumar ni promediar.',
      'perMeasure':
          'Los promedios por día, semana o mes solo sirven para cantidades que se suman, como series, repeticiones, volumen, distancia, tiempo, días y kcal. Pregunta por el peso máximo o medio en un periodo.',
      'shareMeasure':
          'Un porcentaje del total solo se puede calcular con cantidades que se suman, como series o volumen.',
      'trainedMeasure':
          'Elegir días con o sin entrenamiento solo sirve para las kcal comidas y quemadas. Los registros de entrenamiento son todos de días entrenados.',
      'sameSeries':
          'Los dos lados de la comparación se leyeron iguales. Indica qué comparar con qué.',
      'other':
          'La búsqueda de registros no puede calcular una pregunta con esta forma. Pregunta por partes.',
    });
    return '$_temp0';
  }

  @override
  String policyNumberRejected(String text, String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'decimal':
          '\'$text\': no se aceptan decimales. Escribe un número entero, p. ej. 14',
      'range': '\'$text\': escribe un solo número, no un rango, p. ej. 14',
      'negative': '\'$text\': no se aceptan números menores que 0, p. ej. 14',
      'unit':
          '\'$text\': este campo cuenta días o sesiones. Convierte horas, semanas o meses a días, p. ej. 14',
      'many': '\'$text\': escribe solo un número, p. ej. 14',
      'other':
          'No se pudo leer un número de días o sesiones en \'$text\'. Escribe un número, p. ej. 14',
    });
    return '$_temp0';
  }

  @override
  String get mealSources => 'Fuente';

  @override
  String get mealSourcesTitle => 'De dónde salen las calorías';

  @override
  String get mealSourcesNote =>
      'Calculado con los valores de la tabla de abajo. Toca uno para abrir ese nombre en la tabla original. Lo que no está en la tabla lo estimó la IA.';

  @override
  String mealSourcePer(String unit, String kcal) {
    return '$kcal kcal por 100 $unit';
  }

  @override
  String get mealSourceMfds =>
      'Base de datos de composición de alimentos del MFDS (Corea)';

  @override
  String get mealSourceUsda => 'USDA FoodData Central';

  @override
  String get mealAmountInvalid => 'Introduce un número igual o mayor que 0.';

  @override
  String dayEnergyFull(String intake, String burned, String diff) {
    return 'Ingesta $intake · ejercicio $burned = $diff kcal';
  }

  @override
  String dayEnergyApprox(String intake, String burned, String diff) {
    return 'Ingesta ≈ $intake · ejercicio $burned ≈ $diff kcal';
  }

  @override
  String get dayBurnedMissing =>
      'Energía del ejercicio sin medir · sin diferencia';

  @override
  String dayBurnedOnly(String n) {
    return 'Ejercicio $n kcal · sin comidas registradas';
  }

  @override
  String get intakeLabel => 'Ingesta';

  @override
  String get partnerSignIn => 'Inicia sesión para entrenar juntos.';

  @override
  String get partnerSignInAction => 'Iniciar sesión';

  @override
  String get partnerMakeCode => 'Crear código';

  @override
  String get partnerCopy => 'Copiar';

  @override
  String partnerExpiresIn(String t) {
    return 'Caduca en $t';
  }

  @override
  String get partnerExpired => 'El código ha caducado.';

  @override
  String get partnerNewCode => 'Nuevo código';

  @override
  String get partnerStopWaiting => 'Dejar';

  @override
  String partnerWith(String name) {
    return 'Entrenando con $name';
  }

  @override
  String get partnerReconnecting =>
      'Reconectando · tu registro se sigue guardando';

  @override
  String partnerTheirRecord(String name) {
    return 'Registro de $name';
  }

  @override
  String get partnerNoRecordYet => 'Aún no hay nada registrado.';

  @override
  String get partnerLoading => 'Cargando…';

  @override
  String get partnerEnd => 'Dejar de entrenar juntos';

  @override
  String get partnerEndedByMe =>
      'Dejaste de entrenar juntos. Tu registro se conserva.';

  @override
  String partnerEndedByThem(String name) {
    return '$name dejó de entrenar contigo. Tu registro se conserva.';
  }

  @override
  String get partnerErrFormat => 'El código tiene seis caracteres. Revísalo.';

  @override
  String get partnerErrInvalid =>
      'No existe ese código. Puede estar usado o mal escrito.';

  @override
  String get partnerErrExpired => 'Ese código ha caducado. Pide uno nuevo.';

  @override
  String get partnerErrEnded => 'Esa invitación ya terminó.';

  @override
  String get partnerErrOwn =>
      'Es tu propio código. Introdúcelo en el otro teléfono.';

  @override
  String get partnerErrTries => 'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get partnerErrNetwork =>
      'No se pudo conectar al servidor. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get partnerErrServer =>
      'El servidor tuvo un problema. Inténtalo en un momento.';

  @override
  String get partnerRetry => 'Reintentar';

  @override
  String get partnerReadOnly => 'solo lectura';

  @override
  String get partnerConflict =>
      'Otro de tus dispositivos compartió un registro más reciente. El de este dispositivo está a salvo; solo se pausó el compartir.';

  @override
  String get partnerShareThisDevice =>
      'Compartir el registro de este dispositivo';

  @override
  String get plansTitle => 'Planes compartidos';

  @override
  String get planNew => 'Nuevo plan compartido';

  @override
  String get planJoin => 'Unirse con código';

  @override
  String get planHint =>
      'La primera línea es el título; luego un ejercicio por línea\np. ej. Sentadilla 4 series';

  @override
  String get planDateNone => 'Sin fecha';

  @override
  String planSetsCount(int n) {
    return '$n series';
  }

  @override
  String get planSave => 'Proponer';

  @override
  String get planStateLocal =>
      'Borrador solo en este dispositivo · aún no está en el servidor';

  @override
  String get planStateDraft => 'Borrador · aún sin compañero';

  @override
  String planStateWaiting(int v) {
    return 'Esperando a tu compañero · versión $v';
  }

  @override
  String planStateNeedsMe(String name, int v) {
    return '$name lo cambió · la versión $v necesita tu OK';
  }

  @override
  String planStateAgreed(int v) {
    return 'Acordado · versión $v';
  }

  @override
  String get planStateWithdrawn =>
      'La planificación compartida terminó · se conservan el plan acordado y tus objetivos';

  @override
  String planAccept(int v) {
    return 'Aceptar versión $v';
  }

  @override
  String get planChanged => 'Cambios desde el último plan acordado';

  @override
  String planAdded(String x) {
    return 'Añadido: $x';
  }

  @override
  String planRemoved(String x) {
    return 'Quitado: $x';
  }

  @override
  String planSetsChanged(String x) {
    return 'Series cambiadas: $x';
  }

  @override
  String get planReordered => 'Cambió el orden';

  @override
  String get planDateChanged => 'Cambió la fecha';

  @override
  String get planTitleChanged => 'Cambió el título';

  @override
  String planLastAgreed(int v) {
    return 'Último plan acordado · versión $v';
  }

  @override
  String get planConflict =>
      'Tu compañero lo cambió antes. Tu borrador sigue aquí.';

  @override
  String planLatest(int v) {
    return 'Último plan de tu compañero · versión $v';
  }

  @override
  String get planKeepMine => 'Volver a proponer mi borrador';

  @override
  String get planTakeLatest => 'Usar el plan más reciente';

  @override
  String get planMyTarget => 'Mi objetivo';

  @override
  String planPartnerTarget(String name, String t) {
    return '$name: $t';
  }

  @override
  String get planTargetHint => 'p. ej. 100 5 o 100kg 5 reps x3 nota';

  @override
  String get planInvite => 'Crear código de invitación';

  @override
  String get planStart => 'Empezar este plan';

  @override
  String get planStartSolo => 'Empezar mi propia copia';

  @override
  String get planStartSoloNote =>
      'Aún no hay acuerdo. Si empiezas ahora usarás tu propia copia, no un plan acordado.';

  @override
  String get planOpenWorkout => 'Abrir el entrenamiento';

  @override
  String get planCopyNext => 'Copiar al siguiente entrenamiento';

  @override
  String get planWithdraw => 'Salir de este plan compartido';

  @override
  String get planCompare => 'Plan y realidad';

  @override
  String planDoneSets(String name, int planned, int done) {
    return '$name · plan $planned · hechas $done';
  }

  @override
  String planAddedActual(String x) {
    return 'Fuera del plan: $x';
  }

  @override
  String planSkipped(String x) {
    return 'Omitido: $x';
  }

  @override
  String planStartedFrom(int v) {
    return 'Empezó desde el plan acordado (versión $v)';
  }

  @override
  String planStartedSolo(int v) {
    return 'Empezó desde tu propia copia (versión $v, sin acuerdo)';
  }

  @override
  String get planShareLink => 'Enviar enlace de invitación';

  @override
  String planShareText(String url) {
    return 'Planeemos juntos el entrenamiento en setpad: $url';
  }

  @override
  String get planLinkCopied => 'Enlace copiado. Sirve una vez, durante un día.';

  @override
  String get planLinkJoining => 'Uniéndote al plan al que te invitaron…';

  @override
  String get nearbyHint =>
      'Entre iPhones también puedes conectar acercando los dos teléfonos con esta pantalla abierta.';

  @override
  String get planPropose => 'Proponer plan';

  @override
  String get togetherStart => 'Empezar juntos';

  @override
  String get togetherAlternate => 'Por turnos';

  @override
  String togetherWaiting(String name) {
    return 'Esperando a $name…';
  }

  @override
  String get togetherWaitingHint =>
      'La solicitud aparece en la pantalla de tu compañero. Si no, comprueba que su app esté actualizada.';

  @override
  String togetherInvite(String name) {
    return '$name quiere hacerlo contigo';
  }

  @override
  String get togetherInviteAlternate => 'Por turnos · empieza tu compañero';

  @override
  String get togetherLeave => 'Parar';

  @override
  String get togetherRejoin => 'Volver a entrar';

  @override
  String togetherWith(String name) {
    return 'Junto con $name';
  }

  @override
  String get togetherTheirTurn => 'Turno de tu compañero';

  @override
  String togetherLeftBeat(String name, int n) {
    return '$name paró en el pulso $n';
  }

  @override
  String togetherLeftRound(String name, int n) {
    return '$name paró en la ronda $n';
  }

  @override
  String get togetherMe => 'Yo';

  @override
  String get togetherLog => 'Anotar';

  @override
  String get mealLogAs => 'Anotar como comida';

  @override
  String get mealAutoLogged => 'Guardado como comida';

  @override
  String get mealAutoUndo => 'Cambiar a ejercicio';

  @override
  String get proxyWrite => 'Anotar por él';

  @override
  String proxyWriting(String name) {
    return 'Anotando el entrenamiento de $name';
  }

  @override
  String get proxyDefaultName => 'Compañero';

  @override
  String get proxyHand => 'Entregar';

  @override
  String get proxyBack => 'Volver al mío';

  @override
  String proxyShareText(String url) {
    return 'Un entrenamiento que anoté por ti. Ábrelo en setpad para añadirlo a tu registro.\n$url';
  }

  @override
  String handoffOffer(String name) {
    return '$name anotó tu entrenamiento por ti';
  }

  @override
  String get handoffTake => 'Recibir';

  @override
  String get handoffFailed =>
      'No se pudo recibir el registro. El enlace puede haber caducado o no hay conexión.';

  @override
  String get handoffSignIn =>
      'Inicia sesión para recibir un registro que te entregaron.';

  @override
  String partnerInviteMore(String code) {
    return 'Invitar a uno más · código $code';
  }

  @override
  String get proxyWhose => '¿De quién es el entrenamiento?';

  @override
  String planMemberAccepted(String name) {
    return '$name de acuerdo';
  }

  @override
  String planMemberWaiting(String name) {
    return '$name aún no ha confirmado';
  }

  @override
  String deleteNoteAsk(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String get mealsTitle => 'Comidas';

  @override
  String get energyBurned => 'Ejercicio';

  @override
  String get energyDifference => 'Diferencia';

  @override
  String get energyDiffFormula => 'Comido − ejercicio';

  @override
  String get energyDiffExplain =>
      'Calorías que registraste comiendo menos las que quemaste entrenando. Positivo: comiste más de lo que quemaste entrenando; negativo: menos.\n\nNo incluye tu metabolismo en reposo ni la actividad diaria, así que no equivale a tu cambio de peso.';

  @override
  String get estimateTag => 'aprox.';

  @override
  String get energyNotLogged => 'Sin registro';

  @override
  String get energyNotMeasured => 'Sin medir';

  @override
  String get recordMenu => 'Más';

  @override
  String dayIntakeOnly(String intake) {
    return 'Ingesta $intake kcal · energía del ejercicio sin medir';
  }

  @override
  String dayIntakeOnlyApprox(String intake) {
    return 'Ingesta ≈ $intake kcal · energía del ejercicio sin medir';
  }

  @override
  String dayUnknownMeals(int m) {
    return '$m sin kcal conocidas';
  }

  @override
  String get healthDataTitle => 'Datos de salud';

  @override
  String get healthDataIntro =>
      'Lo que setpad intercambia con tu app de salud (Salud de Apple, Health Connect) y por qué.';

  @override
  String get healthDataWrite =>
      'Escritura · Entrenamientos — al terminar un registro, se guarda como una sesión de entrenamiento.';

  @override
  String get healthDataCalories =>
      'Lectura · Calorías activas — las calorías activas que midió tu reloj durante el entrenamiento se añaden a ese registro. Si no se midió nada, no se muestran calorías.';

  @override
  String get healthDataHeart =>
      'Lectura · Frecuencia cardiaca — durante el descanso de un Tabata, cuando tu pulso baja 25 lpm por debajo del máximo de esa ronda, el descanso termina y se avisa la siguiente ronda. Mientras descansas, la línea del temporizador muestra ♥ ahora → objetivo. Sin pulso, o con una lectura de más de 90 segundos, el descanso termina a su hora.';

  @override
  String get healthDataStays =>
      'Lo que se lee de tu app de salud nunca sale de este dispositivo. No se envía a ningún servidor ni se usa para publicidad o marketing.';

  @override
  String get healthDataRevokeIos =>
      'Puedes desactivarlos cuando quieras en Ajustes del iPhone → Privacidad y seguridad → Salud → setpad.';

  @override
  String get healthDataRevokeAndroid =>
      'Puedes desactivarlos cuando quieras en Health Connect → Permisos de apps → setpad.';

  @override
  String get healthDataPrivacy => 'Política de privacidad';

  @override
  String get restAlarmTitle => 'Siguiente ronda: tu pulso ha bajado';

  @override
  String liveSetBusy(String name) {
    return '$name está editando esta serie. Tócala de nuevo cuando termine.';
  }

  @override
  String liveExerciseBusy(String name) {
    return '$name está escribiendo en este ejercicio ahora mismo.';
  }

  @override
  String liveExerciseRemoved(String exercise) {
    return 'Alguien de tu sesión eliminó $exercise. Lo que escribías sigue en la línea de entrada.';
  }

  @override
  String get trainerReport => 'Informe del entrenador';

  @override
  String get trainerUnread => 'Informe nuevo';

  @override
  String trainerRanAt(String when) {
    return 'Preparado $when';
  }

  @override
  String get trainerRunNow => 'Preparar ahora';

  @override
  String get trainerNoReport => 'Aún no hay informe. ¿Preparar uno ahora?';

  @override
  String get trainerOutdated =>
      'Este informe requiere una versión más reciente. Actualiza la app.';

  @override
  String get trainerFailed =>
      'No se pudo conectar con el servidor. Inténtalo de nuevo en un momento.';

  @override
  String get trainerActUnknown =>
      'No se pudo confirmar el resultado. Si vuelves a tocar, no se registrará dos veces.';

  @override
  String get trainerDone => 'Hecho por el agente';

  @override
  String get trainerToday => 'Sesiones de hoy';

  @override
  String get trainerTodo => 'Por revisar';

  @override
  String get trainerAllClear => 'Ya está todo revisado.';

  @override
  String get trainerAttendance => 'Sesiones por cerrar';

  @override
  String trainerVisited(String time) {
    return 'Visita confirmada $time';
  }

  @override
  String trainerFinishAll(int count) {
    return 'Completar todo ($count)';
  }

  @override
  String trainerFinishAsk(int count) {
    return 'Completar $count: se descuenta una sesión del bono de PT por cada una.';
  }

  @override
  String get trainerFinish => 'Completar';

  @override
  String get trainerJoinRequest =>
      'Solicitud de alta: revísala en la pantalla Hoy del CRM web.';

  @override
  String get trainerBook => 'Reservar';

  @override
  String get trainerSend => 'Enviar';

  @override
  String get trainerPaid => 'Pago recibido';

  @override
  String get trainerContacted => 'Contactado';

  @override
  String get trainerLater => 'Más tarde';

  @override
  String trainerPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '₩$priceString';
  }

  @override
  String trainerStarts(String d) {
    return 'Desde $d';
  }

  @override
  String get trainerPayHow => '¿Cómo se pagó?';

  @override
  String get trainerPaidListPrice =>
      'Se registra el precio completo como pagado. Para un descuento o un pago dividido, regístralo en la pestaña Membresía del miembro en el CRM web.';

  @override
  String get payCard => 'Tarjeta';

  @override
  String get payCash => 'Efectivo';

  @override
  String get payTransfer => 'Transferencia';

  @override
  String get payOther => 'Otro';

  @override
  String get agentSettings => 'Ajustes del agente';

  @override
  String get agentEnabled => 'Preparar a las horas fijadas';

  @override
  String get agentTimes => 'Horas del informe';

  @override
  String get agentAddTime => 'Añadir hora';

  @override
  String get agentDays => 'Días';

  @override
  String get agentAutoConfirm => 'Confirmar solicitudes de PT al instante';

  @override
  String get agentModes => 'Por tarea';

  @override
  String get agentModesHelp =>
      'Manual: el agente no lo toca. Borrador: el agente lo prepara y tú lo terminas con un toque. Auto: el agente lo hace.';

  @override
  String get agentModeOff => 'Manual';

  @override
  String get agentModeDraft => 'Borrador';

  @override
  String get agentModeAuto => 'Auto';

  @override
  String get taskPtSchedule => 'Agenda de PT';

  @override
  String get taskRenewal => 'Renovaciones';

  @override
  String get taskAttendance => 'Asistencia';

  @override
  String get taskRoutine => 'Rutinas';

  @override
  String get taskContact => 'Contacto con socios';

  @override
  String get gymPolicy => 'Política del gimnasio';

  @override
  String get policyRenewalDays =>
      'Momento del aviso de renovación (días antes)';

  @override
  String get policyLowSessions => 'Umbral de PT bajo (sesiones reservables)';

  @override
  String get policyAwayDays => 'Ausente tras (días)';

  @override
  String get policyLapsedDays => 'Baja tras (días)';

  @override
  String get policyOffer => 'Texto de la oferta de renovación';

  @override
  String get policySave => 'Guardar política';

  @override
  String get policySaved => 'Guardado.';

  @override
  String get trainerWhichGym => '¿Qué gimnasio?';

  @override
  String get trainerBack => 'Volver';

  @override
  String get trainerCopy => 'Copiar mensaje';

  @override
  String get trainerCopied => 'Copiado';

  @override
  String get settingsTrainer => 'Entrenador';

  @override
  String get aiSetting => 'Ayuda de IA';

  @override
  String get aiOff =>
      'La ayuda de IA está desactivada, así que se guardó tal cual. Actívala en Ajustes › Ayuda de IA';

  @override
  String get aiOffPhoto =>
      'La ayuda de IA está desactivada, así que la foto no se estimó. Escribe la comida como texto, p. ej. ‘arroz 200kcal’, y entra tal cual';

  @override
  String get answerNeedsTwoDays => 'Hacen falta al menos dos días';

  @override
  String get answerNoBase => 'Sin valor de referencia';

  @override
  String answerPerWeek(String value) {
    return '$value por semana';
  }

  @override
  String answerPerMonth(String value) {
    return '$value al mes';
  }

  @override
  String answerTimesAfter(int n) {
    return '$n sesiones desde el récord';
  }

  @override
  String get answerTimesUnit => ' veces';

  @override
  String answerTimes(int n) {
    return '$n veces';
  }

  @override
  String answerStreak(int n) {
    return '$n días seguidos';
  }

  @override
  String answerRestDays(int n) {
    return '$n días de descanso';
  }

  @override
  String get answerUntilToday => 'hoy';

  @override
  String answerEveryDays(String value) {
    return 'Normalmente cada $value días';
  }

  @override
  String answerMeanEvery(String value) {
    return 'De media cada $value días';
  }

  @override
  String answerGapSpread(int a, int b, int c, int d) {
    return 'Seguidos $a · tras 1 día de descanso $b · tras 2 $c · tras 3+ $d';
  }

  @override
  String answerLongestIncluded(int n) {
    return 'Incluye un descanso de $n días';
  }

  @override
  String get answerNoMeals => 'No hay días con comidas registradas';

  @override
  String answerAbout(String value) {
    return 'unos $value';
  }

  @override
  String answerMealDays(int n) {
    return '$n días con comidas';
  }

  @override
  String queryUnknownMeals(int n) {
    return '$n comidas sin calorías conocidas no están en el total';
  }

  @override
  String get answerNoWatch => 'No hay entrenos medidos con el reloj';

  @override
  String answerWatchDays(int n) {
    return '$n días medidos con el reloj';
  }

  @override
  String get answerNoBoth =>
      'No hay días con comidas y calorías del reloj a la vez';

  @override
  String answerBothDays(int n) {
    return '$n días con ingesta y gasto';
  }

  @override
  String answerIntakeOnlyDays(int n) {
    return 'Se dejaron fuera $n días solo con comidas';
  }

  @override
  String answerMonths(int n) {
    return '$n meses';
  }

  @override
  String get metricChangePct => 'Cambio %';

  @override
  String get metricDaysSinceBest => 'Días desde el récord';

  @override
  String get metricSessionsSinceBest => 'Sesiones desde el récord';

  @override
  String get metricMeanReps => 'Reps por serie';

  @override
  String get metricLongestStreak => 'Racha más larga';

  @override
  String get metricLongestGap => 'Pausa más larga';

  @override
  String get metricMeanGap => 'Días entre entrenos';

  @override
  String get metricIntake => 'Calorías ingeridas';

  @override
  String get metricBurned => 'Calorías quemadas';

  @override
  String get metricBalance => 'Ingeridas − quemadas';

  @override
  String get queryAlone => 'A solas';

  @override
  String get queryTogether => 'Con compañero';

  @override
  String get queryByPart => 'Por zona';

  @override
  String get queryCanSee =>
      'El registro puede mostrar pesos, repeticiones, series, días de entreno y calorías de comidas';

  @override
  String get queryDiffColumn => 'Diferencia';

  @override
  String get queryFutureCell => 'Aún no ha llegado';

  @override
  String get queryGrowthRate =>
      'El progreso se ordena por ritmo semanal, para comparar periodos distintos con justicia';

  @override
  String get queryHandoff => 'Solo registros recibidos';

  @override
  String get queryNoHandoff => 'Sin registros recibidos';

  @override
  String queryHandoffCount(int n) {
    return 'Se excluyen $n registros recibidos';
  }

  @override
  String get queryHoursNote =>
      'La hora es la de creación del registro; lo que anotaste después cuenta a esa hora';

  @override
  String get queryMixedWeights => 'Estos pesos mezclan varios ejercicios';

  @override
  String get queryNcBodyweight =>
      'El peso corporal no está en el registro. Escríbelo en la pregunta y se compara (p. ej.: peso 80, ¿cuántas veces es mi peso muerto?)';

  @override
  String get queryNcWeightForecast =>
      'No se calcula el peso futuro: el registro tiene lo que comiste y lo que quemaron los entrenamientos, pero no tu metabolismo en reposo ni la actividad diaria';

  @override
  String get queryNcHeartRate =>
      'La búsqueda aún no mira el pulso; por ejercicio o descanso no puede, porque las series no tienen hora';

  @override
  String get queryNeverMark => 'Nunca registrado';

  @override
  String get queryNoBaseRatio => 'Sin valor de referencia no hay proporción';

  @override
  String get queryNoneCell => 'Sin registros en este rango';

  @override
  String get queryNoRoutine => 'Sin rutina';

  @override
  String get queryRoutine => 'Con rutina del entrenador';

  @override
  String get queryOngoing => 'en curso';

  @override
  String get queryOverlap =>
      'Los días de entreno se solapan, no hay reparto; pregunta por series';

  @override
  String queryPart(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'chest': 'Pecho',
      'back': 'Espalda',
      'legs': 'Piernas',
      'shoulders': 'Hombros',
      'arms': 'Brazos',
      'core': 'Core',
      'cardio': 'Cardio',
      'upper': 'Tren superior',
      'lower': 'Tren inferior',
      'other': 'Zona',
    });
    return '$_temp0';
  }

  @override
  String get queryRatioColumn => 'Proporción';

  @override
  String get queryRatioUnits => 'Unidades distintas, no hay proporción';

  @override
  String get queryRestDay => 'Días de descanso';

  @override
  String get queryTrained => 'Días de entreno';

  @override
  String get querySetFirst => 'Primera serie';

  @override
  String get querySetLast => 'Última serie';

  @override
  String get queryShare => 'Reparto';

  @override
  String get queryZeroFilled => 'Los ejercicios que no hiciste cuentan como 0';

  @override
  String queryAgainst(String value) {
    return 'frente a $value';
  }

  @override
  String queryAgainstLine(
    String value,
    String target,
    String ratio,
    String diff,
  ) {
    return '$value ÷ $target = $ratio× · diferencia $diff';
  }

  @override
  String queryAlias(String name, String names) {
    return '$name = $names';
  }

  @override
  String queryDayCount(int n) {
    return '$n días';
  }

  @override
  String queryDroppedSets(int n) {
    return 'Se excluyen $n series con otros valores';
  }

  @override
  String queryHours(int from, int to) {
    return '$from:00–$to:00';
  }

  @override
  String queryMaybe(String name) {
    return '¿Quisiste decir $name?';
  }

  @override
  String queryMemoAll(String terms) {
    return 'La nota tiene todo: $terms';
  }

  @override
  String queryMemoHit(String text, int n) {
    return '$text ($n días)';
  }

  @override
  String queryMemoHits(String hits) {
    return 'Notas encontradas: $hits';
  }

  @override
  String queryNeverPartial(String names) {
    return '$names: sin registros, se contó sin ellos';
  }

  @override
  String queryNeverRows(String names) {
    return '$names: sin registros';
  }

  @override
  String queryNoMemo(String terms) {
    return 'Nota sin: $terms';
  }

  @override
  String queryNoRepsSets(int n) {
    return 'Se excluyen $n series sin repeticiones';
  }

  @override
  String queryNotComputable(String things) {
    return 'No está en el registro, no se muestra: $things';
  }

  @override
  String queryNotComputableTail(String things) {
    return 'No se puede ver: $things';
  }

  @override
  String queryNothingComputable(String things) {
    return 'El registro no puede responder esto: $things';
  }

  @override
  String queryNoWeightSets(int n, int reps) {
    return 'Se excluyen $n series sin peso (hasta $reps reps)';
  }

  @override
  String queryNth(int n) {
    return 'Día de entreno $n desde el final';
  }

  @override
  String queryOtherDistance(int n, String value) {
    return '$n series con distancia: $value';
  }

  @override
  String queryOtherDuration(int n, String value) {
    return '$n series con tiempo: $value';
  }

  @override
  String queryPartial(String names) {
    return 'sin $names';
  }

  @override
  String queryPartialChunk(int n) {
    return '($n días)';
  }

  @override
  String queryPartMembers(String part, String names) {
    return '$part: $names';
  }

  @override
  String queryPer(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': 'por día',
      'week': 'por semana',
      'month': 'al mes',
      'other': 'media',
    });
    return '$_temp0';
  }

  @override
  String queryPerSuffix(String per) {
    String _temp0 = intl.Intl.selectLogic(per, {
      'day': '/día',
      'week': '/sem',
      'month': '/mes',
      'other': '/',
    });
    return '$_temp0';
  }

  @override
  String queryRatioHead(String a, String b) {
    return '$a ÷ $b';
  }

  @override
  String queryRatioLine(String a, String b, String value, String percent) {
    return '$a ÷ $b = $value× ($percent%)';
  }

  @override
  String queryRelative(String by, int n) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'day': 'Día $n',
      'week': 'Semana $n',
      'month': 'Mes $n',
      'other': 'N.º $n',
    });
    return '$_temp0';
  }

  @override
  String queryRolled(String year) {
    return 'Aún no llega, se leyó como $year';
  }

  @override
  String querySamePeriod(int days, String earlier, String later) {
    return 'Mismos $days días: $earlier → $later';
  }

  @override
  String queryShortGrowth(String names) {
    return 'Demasiado corto para clasificar (menos de 3 días o 3 semanas): $names';
  }

  @override
  String queryTimer(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': 'Tabata',
      'bpm': 'Temporizador BPM',
      'other': 'Sin temporizador',
    });
    return '$_temp0';
  }

  @override
  String queryUnknownPart(String names) {
    return 'Se excluyen ejercicios sin zona conocida: $names';
  }

  @override
  String queryUnranked(int n, String names) {
    return '$n fuera del ranking por valores faltantes: $names';
  }

  @override
  String queryWindowLengths(String lengths) {
    return 'Los periodos tienen distinta duración ($lengths días); diferencias y proporciones son por semana';
  }

  @override
  String queryZeroBuckets(String by, int total, int zeros) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'week': '$zeros de $total semanas en 0',
      'month': '$zeros de $total meses en 0',
      'other': '$zeros de $total en 0',
    });
    return '$_temp0';
  }

  @override
  String queryPossibleDays(int m, String percent) {
    return '$percent% de $m días posibles';
  }

  @override
  String get queryOfflineLocal =>
      'No se pudo conectar con el servidor; se contó en tu dispositivo solo con los ejercicios y fechas del texto. Pulsa Enter para preguntar de nuevo con conexión.';

  @override
  String get queryMisread =>
      'No se pudo convertir esta pregunta en algo que contar. Prueba a formularla de otra manera.';

  @override
  String get queryMisreadLocal =>
      'No se pudo interpretar la pregunta; se contó en tu dispositivo solo con los ejercicios y el periodo del texto. Reformúlala para volver a preguntar.';

  @override
  String get queryUnreadable =>
      'El modelo envió dos veces una respuesta ilegible. No es tu conexión, y esa respuesta no gastó discos.';

  @override
  String get queryAskAgain => 'Preguntar de nuevo';

  @override
  String get queryUnreadablePaid =>
      'El modelo envió dos veces una respuesta ilegible. No es tu conexión. Esa respuesta no gastó discos; los discos de abajo son del primer paso, que clasificó tu pregunta.';

  @override
  String get queryUnreadableLocal =>
      'Mientras tanto, se contó en tu dispositivo con los ejercicios y el periodo del texto.';

  @override
  String get queryTotalUnits => 'Las unidades son distintas; no hay total';

  @override
  String queryMemoDropped(String words) {
    return 'Condición de nota omitida: $words';
  }

  @override
  String queryAgainstDropped(String value) {
    return 'Número de referencia $value omitido: no es un peso escrito en la pregunta';
  }

  @override
  String routineDate(DateTime d) {
    final intl.DateFormat dDateFormat = intl.DateFormat.Md(localeName);
    final String dString = dDateFormat.format(d);

    return '$dString';
  }

  @override
  String get routineHeaderToday => 'Rutina de hoy';

  @override
  String routineHeaderDay(String day) {
    return 'Rutina de $day';
  }

  @override
  String routineTomorrow(String date) {
    return 'mañana ($date)';
  }

  @override
  String routineWhyRotation(String date, int days) {
    return 'Hace $days días que no haces el entreno del $date — armada como ese día';
  }

  @override
  String routineWhyFrom(String date) {
    return 'Igual que el $date';
  }

  @override
  String routineWhyNamed(String date) {
    return 'Completada con lo que hiciste junto a eso el $date';
  }

  @override
  String routinePartRest(String list) {
    return 'Últimos 28 días: hace $list';
  }

  @override
  String routinePartDays(String part, int days) {
    return '$part $days d';
  }

  @override
  String routineEstimate(int minutes) {
    return 'Unos $minutes min';
  }

  @override
  String routinePaceOwn(int sessions, String pace) {
    return 'calculado a $pace por serie según tus últimos $sessions entrenos';
  }

  @override
  String routinePaceDefault(String pace) {
    return 'calculado con el valor por defecto de $pace por serie — registra algunos entrenos para usar tu ritmo';
  }

  @override
  String routineMinSec(int m, int s) {
    return '$m min $s s';
  }

  @override
  String routineReadAs(String list) {
    return 'Leído así: $list';
  }

  @override
  String routineCopied(String date) {
    return 'como el $date';
  }

  @override
  String routineRepsMatched(String date, int reps) {
    return 'peso con el que hiciste $reps reps el $date';
  }

  @override
  String get routineTyped => 'como lo escribiste';

  @override
  String get routineFirst => 'primera vez';

  @override
  String routineBlank(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'light': 'peso en blanco (día suave)',
      'pain': 'peso en blanco (mencionaste dolor)',
      'gear': 'peso en blanco (otro equipo)',
      'bodyweight': 'peso del equipo en blanco',
      'stale': 'peso en blanco (hace tiempo)',
      'repsUnmatched': 'peso en blanco (ningún día con esas series y reps)',
      'other': 'peso en blanco',
    });
    return '$_temp0';
  }

  @override
  String routineReference(String sets, String date) {
    return 'Ref.: $sets ($date)';
  }

  @override
  String routineBest(String set, String date) {
    return 'Ref.: mejor $set ($date)';
  }

  @override
  String routineStepped(String step, String evidence) {
    return '+$step ($evidence)';
  }

  @override
  String routineMemo(String date, String memo) {
    return 'Nota del $date: $memo';
  }

  @override
  String routineRecent(String part, String when) {
    return '$part · $when';
  }

  @override
  String routineDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'hace $n días',
      one: 'ayer',
      zero: 'hoy',
    );
    return '$_temp0';
  }

  @override
  String get routineFuture =>
      'Vista previa — escribe \'rutina\' ese día para empezarla como el registro de ese día';

  @override
  String routineRefused(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'diet':
          'No hago planes de comidas — registra tus comidas para ver las calorías',
      'medical':
          'No juzgo rehabilitación ni entrenos tras una cirugía — registra los ejercicios que te dio tu médico o fisio y los convierto en rutina',
      'drug': 'No ayudo con drogas',
      'program': 'Planifico un día a la vez — esta es la de hoy',
      'logging': 'No marco series como hechas por ti — tócalas al hacerlas',
      'format':
          'No hay temporizador EMOM, superserie ni circuito — solo el orden (tabata y bpm sí)',
      'person':
          'No planifico para otra persona — solo se muestran nombres de ejercicios de tu registro',
      'other': 'Solo ayudo con tu registro y tus rutinas',
    });
    return '$_temp0';
  }

  @override
  String routineNotStated(String what) {
    return 'Quitado, no está en lo que escribiste: $what';
  }

  @override
  String routineUnmet(String what) {
    return 'No se pudo aplicar: $what';
  }

  @override
  String routineKeyName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'when': 'día',
      'from': 'día anterior',
      'parts': 'zona',
      'pattern': 'empuje/tirón',
      'exercises': 'ejercicios',
      'exclude': 'exclusiones',
      'avoid': 'zonas a evitar',
      'pain': 'dolor',
      'equipment': 'equipo',
      'count': 'número de ejercicios',
      'minutes': 'tiempo',
      'intensity': 'intensidad',
      'timer': 'temporizador',
      'targets': 'números escritos',
      'delta': 'cambio de peso',
      'other': 'condición',
    });
    return '$_temp0';
  }

  @override
  String routineUnknownName(String name) {
    return 'No está en el diccionario, quitado: $name';
  }

  @override
  String get routineNoSuchDay => 'No hay ese día — armada con tu registro';

  @override
  String routineExcludeAbsent(String name) {
    return 'No había nada que quitar: $name';
  }

  @override
  String routineNoneMatched(String what) {
    return 'No hay ejercicios de $what registrados — elige para añadir';
  }

  @override
  String routineFewer(int n) {
    return 'Solo hay $n ejercicios en tu registro';
  }

  @override
  String routineOtherUnit(String unit) {
    return 'Las series en $unit quedaron igual';
  }

  @override
  String get routineBpmRange =>
      'El bpm va de 10 a 120 — añadido sin temporizador';

  @override
  String routineIntensityLine(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'light':
          'Suave: una serie menos en cada ejercicio — los pesos son los de la última vez',
      'lightBlank': 'Suave: una serie menos en cada ejercicio',
      'hard': 'Los pesos son los de la última vez',
      'max': 'No elijo el peso del récord — tu mejor marca está al lado',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get routineNoStep => 'Escribe cuánto subir (p. ej. +2,5 kg)';

  @override
  String routinePain(String phrase, String list) {
    return 'Por \'$phrase\', quitado: $list · pesos en blanco · no juzgo si es seguro';
  }

  @override
  String routinePainNone(String phrase) {
    return '\'$phrase\' — nada quitado, pesos en blanco · no juzgo si es seguro';
  }

  @override
  String get routinePainWord => 'dolor';

  @override
  String get routineFirstTime =>
      'Primera vez — elige ejercicios para añadir (sin números)';

  @override
  String routineCountFit(int count, int minutes) {
    return 'Ajustada a $count ejercicios — unos $minutes min';
  }

  @override
  String routineNoMore(int minutes) {
    return 'No hay más ejercicios registrados para añadir — unos $minutes min';
  }

  @override
  String routineOverTime(int minutes) {
    return 'Solo lo que nombraste lleva unos $minutes min';
  }

  @override
  String routineOverUsual(int n, int usual) {
    return 'Se mantienen los $n ejercicios que elegiste: más de los $usual que sueles hacer en una sesión';
  }

  @override
  String routineRecentMemo(String when, String name, String memo) {
    return '$when, nota de $name: $memo';
  }

  @override
  String routineRemoved(String label, String why) {
    return 'Quitado: $label — $why';
  }

  @override
  String routineRemovedWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'named': 'lo nombraste',
      'avoid': 'zona a evitar',
      'unknownPart': 'zona desconocida',
      'gear': 'otro equipo',
      'unknownGear': 'equipo desconocido',
      'otherPart': 'otra zona',
      'user': 'quitado',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get routineRestore => 'Volver a poner';

  @override
  String routineAdd(String name) {
    return '+ $name';
  }

  @override
  String get routineOther => 'Otra';

  @override
  String routinePrevious(String date) {
    return 'Anterior ($date)';
  }

  @override
  String routineByPart(String part) {
    return 'Armar rutina de $part';
  }

  @override
  String routineStepChip(String step) {
    return '+$step (tu propio incremento)';
  }

  @override
  String routineAskToo(String text) {
    return 'Preguntar también: $text · discos';
  }

  @override
  String get routineAsQuestion => 'Preguntar sobre el registro · discos';

  @override
  String get routineNoConditions => 'Armar ya sin condiciones';

  @override
  String get routineWithConditions => 'Leer también las condiciones · discos';

  @override
  String get routineMake => 'Armar la rutina de hoy';

  @override
  String routineMakePart(String part) {
    return 'Armar rutina de $part de hoy';
  }

  @override
  String get routineStart => 'Empezar';

  @override
  String get routineStarted => 'Empezada · Abrir';

  @override
  String get routineWorking => 'Leyendo las condiciones…';

  @override
  String get routineOffline =>
      'Sin conexión no pude leer las condiciones — armada solo con tu registro';

  @override
  String get routineMisread =>
      'No pude leer las condiciones — armada solo con tu registro. Reformúlalo para leer de nuevo';

  @override
  String routineHeldBack(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'offline': 'Sin conexión',
      'noPlates': 'Sin discos',
      'other': 'La respuesta no se pudo leer',
    });
    return '$_temp0: no pude leer las condiciones (exclusiones, dolor), así que no armé la rutina';
  }

  @override
  String routineTypedWeight(int count, String from, String to) {
    return 'Peso escrito: $count series efectivas $from → $to';
  }

  @override
  String get routineTypedKept => 'el peso escrito se mantiene';

  @override
  String get routinePlatesBefore =>
      'Ya usaste discos con este texto · 0 esta vez';

  @override
  String get routineRetry => 'Reintentar';

  @override
  String get routinePressEnter =>
      'Pulsa Intro para leer también las condiciones · discos';

  @override
  String get routineFromQuestion => 'Leído como petición de rutina';

  @override
  String routinePattern(String p) {
    String _temp0 = intl.Intl.selectLogic(p, {
      'push': 'empuje',
      'pull': 'tirón',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineGear(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'barbell': 'barra',
      'dumbbell': 'mancuernas',
      'machine': 'máquina',
      'cable': 'polea',
      'bodyweight': 'peso corporal',
      'bar': 'barra de dominadas',
      'kettlebell': 'pesa rusa',
      'band': 'banda',
      'bench': 'banco',
      'other': 'equipo',
    });
    return '$_temp0';
  }

  @override
  String routineGearOnly(String list) {
    return 'solo $list';
  }

  @override
  String routineGearWithout(String list) {
    return 'sin $list';
  }

  @override
  String routineMinutes(int n) {
    return '$n min';
  }

  @override
  String routineCount(int n) {
    return '$n ejercicios';
  }

  @override
  String routineIntensity(String k) {
    String _temp0 = intl.Intl.selectLogic(k, {
      'light': 'suave',
      'hard': 'pesado',
      'max': 'intento de récord',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineExclude(String list) {
    return 'quitar: $list';
  }

  @override
  String routineAvoid(String list) {
    return 'evitar: $list';
  }

  @override
  String get routinePlatesZero => '0 discos';

  @override
  String get routineFullBody => 'Cuerpo completo';

  @override
  String get routineNoPlates =>
      'Sin discos no pude leer las condiciones — armada solo con tu registro';

  @override
  String get routineBack => 'Volver a la rutina';

  @override
  String queryBoundDropped(String value) {
    return 'Se quitó la condición $value: la pregunta no dice ese número en esa unidad';
  }

  @override
  String get anatomyTitle => 'Mapa del cuerpo';

  @override
  String get anatomyOpen =>
      'Mapa del cuerpo — ejercicios y consejos de técnica por músculo';

  @override
  String get anatomyPick => 'Elegir ejercicios en el mapa corporal';

  @override
  String get anatomyFront => 'Frente';

  @override
  String get anatomyBack => 'Espalda';

  @override
  String anatomyDays(int n) {
    return '$n días';
  }

  @override
  String muscleName(String m) {
    String _temp0 = intl.Intl.selectLogic(m, {
      'chest': 'Pecho',
      'frontDelts': 'Deltoides anterior',
      'sideDelts': 'Deltoides lateral',
      'rearDelts': 'Deltoides posterior',
      'traps': 'Trapecio superior',
      'upperBack': 'Espalda media',
      'lats': 'Dorsales',
      'lowerBack': 'Zona lumbar',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'forearms': 'Antebrazos',
      'abs': 'Abdominales',
      'obliques': 'Oblicuos',
      'hipFlexors': 'Flexores de cadera',
      'glutes': 'Glúteos',
      'quads': 'Cuádriceps',
      'hamstrings': 'Isquiotibiales',
      'adductors': 'Aductores',
      'calves': 'Gemelos',
      'other': 'Músculo',
    });
    return '$_temp0';
  }

  @override
  String anatomyLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'low': 'poco',
      'mid': 'medio',
      'high': 'mucho',
      'other': 'nada',
    });
    return '$_temp0';
  }

  @override
  String get anatomyLegend =>
      'Cuantas más series tuvo un músculo en este periodo, más oscuro se ve';

  @override
  String get anatomyFirstTime =>
      'Aún no hay series hechas, por eso no hay color. Toca un músculo para ver ejercicios que lo usan y consejos de técnica.';

  @override
  String anatomyEmptyWindow(int n) {
    return 'No hay series hechas en los últimos $n días';
  }

  @override
  String anatomyUnknown(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'No se contaron $n ejercicios de músculos desconocidos',
      one: 'No se contó 1 ejercicio de músculos desconocidos',
    );
    return '$_temp0. Toca un nombre para ver sus registros en la búsqueda.';
  }

  @override
  String anatomyUnknownMore(int n) {
    return 'y $n más';
  }

  @override
  String anatomyCardio(int n) {
    return 'Series de cardio fuera del mapa: $n';
  }

  @override
  String get anatomyCountNote =>
      'Los músculos siguen las clasificaciones de ExRx.net y ACE y son una estimación. En los ejercicios con * la asignación de músculos es una interpretación. Cada serie cuenta una vez para los músculos principales y media para los auxiliares; las series de calentamiento también cuentan.';

  @override
  String get anatomyLimits =>
      'No analiza vídeo ni técnica. Si algo duele, para y consulta a un profesional.';

  @override
  String get anatomyTapHint =>
      'Toca un músculo — también puedes elegirlo en la lista de abajo';

  @override
  String get anatomyNoSurface => 'Músculo profundo, no está en el dibujo';

  @override
  String anatomySets(int days, String sets) {
    return 'Series en $days días: $sets';
  }

  @override
  String anatomySetsLine(String week, String month) {
    return 'Series — últimos 7 días: $week · 28 días: $month';
  }

  @override
  String anatomyBreakdown(int primary, int secondary) {
    return '28 días: como principal $primary · como auxiliar $secondary (cuenta la mitad)';
  }

  @override
  String anatomyLast(String date, String ago) {
    return 'Última vez: $date ($ago)';
  }

  @override
  String get anatomyNever =>
      'Aún no hay series para este músculo entre los ejercicios de la tabla';

  @override
  String get anatomyDone => 'Ejercicios que hiciste';

  @override
  String get anatomyTry => 'Ejercicios que lo usan sobre todo';

  @override
  String anatomyTryGear(String list) {
    return 'Con el equipo que has usado ($list)';
  }

  @override
  String get anatomyAllGear => 'No hay equipo registrado, se muestran todos';

  @override
  String anatomyMoreGear(int n) {
    return '$n más con otro equipo';
  }

  @override
  String get anatomyTriedAll =>
      'Ya hiciste todos los ejercicios que usan sobre todo este músculo';

  @override
  String anatomyRole(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'primary': 'principal',
      'other': 'auxiliar',
    });
    return '$_temp0';
  }

  @override
  String get anatomyInterpNote =>
      '* la asignación de músculos de este ejercicio es una interpretación de su fuente';

  @override
  String get anatomyCues => 'Consejos de técnica';

  @override
  String get anatomyMistakes => 'Evita';

  @override
  String anatomySources(String sites) {
    return 'Fuentes: $sites';
  }

  @override
  String get anatomyUnsourced => '‡ añadido sin fuente';

  @override
  String get anatomyAdapted =>
      '† interpretado a partir del texto de una fuente (incluida la de un ejercicio similar)';

  @override
  String get anatomyCuesEnglish =>
      'Por ahora los consejos de técnica solo están en inglés';

  @override
  String get anatomyAddRoutine => 'Añadir a la rutina de hoy';

  @override
  String anatomyRoutineText(String part) {
    return 'Rutina de $part de hoy';
  }

  @override
  String get anatomySearch => 'Ver en la búsqueda';

  @override
  String anatomyRegionValue(int days, String sets, String level) {
    return 'Series en $days días: $sets, $level';
  }

  @override
  String get anatomyRegionHint => 'Toca dos veces para ver ejercicios';

  @override
  String get anatomyClose => 'Cerrar';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String routineFactor(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': 'Fuerza',
      'endurance': 'Resistencia muscular',
      'sustain': 'Sostenimiento',
      'power': 'Potencia',
      'cardio': 'Cardio',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineFactorDay(String factor, String why) {
    return 'Día de $factor · $why';
  }

  @override
  String routineFactorWhy(String kind, String a, String b) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tabata': 'Tabata $a',
      'fill': 'Completar $a reps',
      'fillTitle': 'Título ‘$a’',
      'distance': '$a',
      'open': '$a reps por serie, series abiertas',
      'single': 'Una serie de $a',
      'drop': 'Máximo por serie $a',
      'hold': '$a reps × $b series',
      'other': '$a×$b',
    });
    return '$_temp0';
  }

  @override
  String routineWhyWeekday(int weeks, String day, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other:
          'Sin registro el $day pasado — armada con el $day de hace $weeks semanas ($date)',
      one: 'Igual que el $day pasado ($date)',
    );
    return '$_temp0';
  }

  @override
  String routineWhyNear(String day, String near) {
    return 'Sin registro del $day — armada con el día cercano $near';
  }

  @override
  String routineWhyFactor(String f, String date) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': 'Esta semana falta fuerza — armada con $date',
      'endurance': 'Esta semana falta resistencia muscular — armada con $date',
      'sustain': 'Esta semana falta sostenimiento — armada con $date',
      'cardio': 'Esta semana falta cardio — armada con $date',
      'other': 'Armada con $date',
    });
    return '$_temp0';
  }

  @override
  String routineWhyFactorAll(String f, String date) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength':
          'Esta semana ya cubriste todo — sigue la fuerza, armada como $date',
      'endurance':
          'Esta semana ya cubriste todo — sigue la resistencia muscular, armada como $date',
      'sustain':
          'Esta semana ya cubriste todo — sigue el sostenimiento, armada como $date',
      'cardio':
          'Esta semana ya cubriste todo — sigue el cardio, armada como $date',
      'other': 'Armada como $date',
    });
    return '$_temp0';
  }

  @override
  String routineWeekCounts(String range, String list) {
    return 'Últimos 7 días ($range): $list';
  }

  @override
  String routineFactorMissing(String list) {
    return 'Sin un día propio en los últimos 28 días: $list';
  }

  @override
  String get routineFillHint =>
      'Para completar, escribe la meta (p. ej. sentadilla completar 100)';

  @override
  String get routineTabataChip => 'Hacerla tabata';

  @override
  String routineLikeLastWeek(String day) {
    return 'Como el $day pasado';
  }

  @override
  String routineFactorChip(String f, int n) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'strength': 'Armar para fuerza · $n esta semana',
      'endurance': 'Armar para resistencia muscular · $n esta semana',
      'sustain': 'Armar para sostenimiento · $n esta semana',
      'cardio': 'Armar para cardio · $n esta semana',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String routineLightKept(String list) {
    return 'Sin cambios (una serie, completar o tabata): $list';
  }

  @override
  String routineWhyWeekdaySkip(String how, int weeks, String day, String date) {
    String _temp0 = intl.Intl.selectLogic(how, {
      'alt': 'Otra rutina: el $day de hace $weeks semanas ($date)',
      'other':
          'El $day pasado solo tenía ejercicios excluidos — armada con el $day de hace $weeks semanas ($date)',
    });
    return '$_temp0';
  }

  @override
  String routineWhyNearSkip(String how, String day, String near) {
    String _temp0 = intl.Intl.selectLogic(how, {
      'alt': 'Otra rutina: el día cercano $near',
      'other':
          'Los registros del $day solo tenían ejercicios excluidos — armada con el día cercano $near',
    });
    return '$_temp0';
  }

  @override
  String routineWhyFactorNoDay(String factor, String date) {
    return 'Los factores que faltan no tienen un día utilizable en los últimos 28 días — armada como el día de $factor del $date';
  }

  @override
  String routineFactorLost(String factor, String date) {
    return 'Armada con el día de $factor del $date, pero sus ejercicios de $factor quedaron fuera';
  }

  @override
  String routineFactorFiltered(String list) {
    return 'Sin día utilizable en los últimos 28 días al quitar lo excluido: $list';
  }

  @override
  String routineLightDropped(String date) {
    return 'una serie menos que el $date';
  }

  @override
  String routineDoneToday(String list) {
    return 'Ya hecho hoy: $list';
  }
}
