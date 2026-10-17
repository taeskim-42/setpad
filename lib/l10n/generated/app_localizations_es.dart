// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class LEs extends L {
  LEs([String locale = 'es']) : super(locale);

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
  String get search => 'Busca o pregunta';

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
  String get aiWorking => 'Configurando ejercicio…';

  @override
  String get aiJudging => 'Leyendo…';

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
  String get moveSetEarlier => 'Mover antes';

  @override
  String get moveSetLater => 'Mover después';

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
  String get queryAmbiguous => 'Aclara a qué ejercicio y registro te refieres.';

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
  String get proSignInOptional =>
      'No hace falta iniciar sesión para comprar. Inicia sesión cuando quieras para usar el plan en tus otros dispositivos.';

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
  String get accountDelete => 'Eliminar cuenta';

  @override
  String get accountDeleteAsk =>
      'Esto no se puede deshacer. Tus rutinas, registros, bonos y reservas desaparecerán. Una suscripción de App Store o Google Play se sigue cobrando hasta que la canceles en la tienda.';

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
  String get mealFailed =>
      'No se pudieron estimar las calorías de esa foto. Prueba otra.';

  @override
  String mealServingsOption(String n) {
    return '$n porción(es)';
  }

  @override
  String get fitAll => 'Entrenamiento de hoy';

  @override
  String sameDayMore(String first, int n) {
    return '$first y $n más';
  }

  @override
  String lastWeekDay(String weekday, String date) {
    return 'El $weekday pasado ($date)';
  }

  @override
  String weeksAgoDay(int n, String weekday, String date) {
    return '$weekday de hace $n semanas ($date)';
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
  String get mealReviewTitle => 'Revisar alimento y cantidad';

  @override
  String get mealReviewNote =>
      'Comprueba los alimentos y las cantidades. Puedes corregir las cantidades abajo. Si el alimento no coincide, cancela y corrige el texto o toma otra foto.';

  @override
  String get mealEstimatedAmount =>
      'La IA estimó esta cantidad. Ajústala a lo que comiste.';

  @override
  String get mealLabelReviewNote =>
      'Compara las calorías, la porción y las unidades con la foto. Corrige los errores antes de guardar.';

  @override
  String get mealTextNeedsReview =>
      'El total de calorías o la cantidad consumida no están claros. Toca la comida e introduce las calorías consumidas o una cantidad precisa.';

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
  String get mealSourceOff => 'Open Food Facts';

  @override
  String mealMacros(String carbs, String protein, String fat) {
    return 'HC $carbs g · P $protein g · G $fat g';
  }

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
  String dayBurnedOnly(String n) {
    return 'Ejercicio $n kcal · sin comidas registradas';
  }

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
  String get nearbyHint =>
      'Entre iPhones también puedes conectar acercando los dos teléfonos con esta pantalla abierta.';

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
  String get mealAutoLogged => 'Guardado como comida';

  @override
  String get mealAutoUndo => 'Cambiar a ejercicio';

  @override
  String get exerciseAutoLogged => 'Guardado como ejercicio';

  @override
  String get exerciseAutoUndo => 'Cambiar a comida';

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
  String deleteNoteAsk(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String mealDeleteAsk(String meal) {
    return '¿Eliminar la comida \"$meal\"?';
  }

  @override
  String get mealsTitle => 'Comidas';

  @override
  String get energyBurned => 'Ejercicio';

  @override
  String get energyDifference => 'Diferencia';

  @override
  String get fold => 'Contraer';

  @override
  String get energySurplus => 'Superávit';

  @override
  String get energyDeficit => 'Déficit';

  @override
  String get milestoneBest => 'Récord de peso';

  @override
  String get energyDiffFormula => 'Comido − ejercicio';

  @override
  String get energyDiffExplain =>
      'Calorías que registraste comiendo menos las que gastaste ese día (metabolismo basal + entrenamientos). Positivo es superávit; negativo, déficit.\n\nEl metabolismo basal sale de la energía en reposo de la app Salud o se calcula con Mi cuerpo (estimación). No incluye la actividad diaria como caminar, así que no equivale a tu cambio de peso.';

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
  String get healthDataBasal =>
      'Lectura · Energía en reposo (metabolismo basal) — se suma a las calorías gastadas del día para compararlas con lo que comiste. Si no hay datos, se calcula con Ajustes › Mi cuerpo.';

  @override
  String get bodyTitle => 'Mi cuerpo';

  @override
  String get bodyNote =>
      'Solo se usa para calcular tu metabolismo basal. Si la app Salud tiene energía en reposo, se usa primero. No sale de tu dispositivo.';

  @override
  String get bodyHeight => 'Altura (cm)';

  @override
  String get bodyWeight => 'Peso (kg)';

  @override
  String get bodyBirthYear => 'Año de nacimiento';

  @override
  String get bodySex => 'Sexo';

  @override
  String get bodyMale => 'Hombre';

  @override
  String get bodyFemale => 'Mujer';

  @override
  String bodyBmr(String kcal) {
    return 'Metabolismo basal de unas $kcal kcal al día (Mifflin-St Jeor)';
  }

  @override
  String get energySpent => 'Gastado';

  @override
  String energySpentNote(String basal, String exercise) {
    return 'Basal $basal + ejercicio $exercise';
  }

  @override
  String get energyDiffFormulaBasal => 'Comido − gastado';

  @override
  String energyLine(String intake, String used, String diff) {
    return 'Comido $intake · gastado $used = $diff kcal';
  }

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
  String get agentTelegram => 'Avisos por Telegram';

  @override
  String get agentTelegramHelp =>
      'Cuando el informe programado esté listo, enviamos solo los recuentos a tu propio Telegram. Sin nombres de socios ni mensajes.';

  @override
  String get agentTelegramConnect => 'Conectar Telegram';

  @override
  String get agentTelegramConnected => 'Conectado';

  @override
  String get agentTelegramDisconnect => 'Desconectar';

  @override
  String get agentTelegramCheck => 'Comprobar conexión';

  @override
  String get agentTelegramWaiting =>
      'Pulsa Iniciar en Telegram y vuelve aquí. El enlace sirve una vez, durante 10 minutos.';

  @override
  String get agentTelegramCopied => 'Enlace copiado. Ábrelo en Telegram.';

  @override
  String get agentTelegramNotYet =>
      'Aún no está conectado. Comprueba que pulsaste Iniciar en Telegram.';

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
  String get routineWhyShow => 'Por qué';

  @override
  String get routineWhyHide => 'Ocultar';

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
    return 'Preguntar también: $text';
  }

  @override
  String get routineAsQuestion => 'Preguntar sobre el registro';

  @override
  String get routineNoConditions => 'Armar ya sin condiciones';

  @override
  String get routineWithConditions => 'Leer también las condiciones';

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
      'infraspinatus': 'Infraespinoso',
      'teresMinor': 'Redondo menor',
      'teresMajor': 'Redondo mayor',
      'tricepsLong': 'Tríceps, cabeza larga',
      'tricepsLateral': 'Tríceps, cabeza lateral',
      'tricepsMedial': 'Tríceps, cabeza medial',
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
  String anatomyBreakdown(int primary, int secondary) {
    return '28 días: como principal $primary · como auxiliar $secondary (cuenta la mitad)';
  }

  @override
  String get anatomyNever =>
      'Aún no hay series para este músculo entre los ejercicios de la tabla';

  @override
  String get anatomyDone => 'Ejercicios que hiciste';

  @override
  String get anatomyTry => 'Ejercicios que lo usan sobre todo';

  @override
  String get anatomyTrySecondary => 'Ejercicios que la usan como apoyo';

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
  String get anatomyZoomReset => 'Tamaño original';

  @override
  String anatomyTileSets(String n) {
    return '$n series';
  }

  @override
  String get anatomyLastLabel => 'Última';

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

  @override
  String kcalEstimated(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '~$nString kcal';
  }

  @override
  String dayBurnedOnlyApprox(String n) {
    return 'Ejercicio $n kcal (est.) · sin comidas';
  }

  @override
  String get bodyRecordsTitle => 'Composición corporal';

  @override
  String get bodyRecordsEmpty => 'Aún no hay registros';

  @override
  String get bodyRecordsNote =>
      'Los registros quedan en este dispositivo. Mantén pulsado para borrar.';

  @override
  String get bodyScanNote =>
      'Fotografía un informe de composición corporal (p. ej. InBody) y la IA lee los valores. La foto solo se envía para leerla y no se guarda. Solo se guardan en el dispositivo los valores que confirmes; el último peso se usa para el metabolismo basal y las estimaciones de ejercicio. Mantén pulsado para borrar.';

  @override
  String get bodyScanCamera => 'Hacer foto';

  @override
  String get bodyScanLibrary => 'Elegir foto';

  @override
  String get bodyScanReading => 'Leyendo el informe…';

  @override
  String get bodyScanFailed =>
      'No se pudo leer. Vuelve a intentarlo con los números bien visibles.';

  @override
  String get bodyReviewTitle => 'Revisa los valores';

  @override
  String get bodyReviewNote =>
      'Corrige lo que no coincida y deja vacío lo que no sepas.';

  @override
  String get bodyMeasuredOn => 'Fecha';

  @override
  String get bodyMuscle => 'Músculo esquelético (kg)';

  @override
  String get bodyFatKg => 'Grasa corporal (kg)';

  @override
  String get bodyFatPercent => 'Grasa corporal (%)';

  @override
  String get bodyBmrField => 'Metabolismo basal (kcal)';

  @override
  String get bodyVisceral => 'Grasa visceral';

  @override
  String get bodyWeightShort => 'Peso';

  @override
  String get bodyMuscleShort => 'Músculo';

  @override
  String get bodyFatShort => 'Grasa';

  @override
  String get bodyRecordDelete => '¿Borrar este registro?';

  @override
  String get mealChooseProduct => 'Elegir otro producto ›';

  @override
  String get mealNeedsChoice =>
      'No hay un producto con este nombre exacto. Elige el que comiste.';

  @override
  String get mealAiEstimate =>
      'Estimación de IA — no está en ninguna tabla de alimentos';

  @override
  String mealChoiceTitle(String food) {
    return '«$food»: ¿qué producto?';
  }

  @override
  String get bodyGoal => 'Objetivo';

  @override
  String get bodyGoalLose => 'Perder grasa';

  @override
  String get bodyGoalMaintain => 'Mantener';

  @override
  String get bodyGoalGain => 'Ganar músculo';

  @override
  String bodyTargets(int kcal, int carbs, int protein, int fat) {
    return 'Objetivo diario $kcal kcal · HC $carbs g · P $protein g · G $fat g';
  }

  @override
  String get bodyTargetsNeed =>
      'Elige un objetivo e introduce peso, altura, año de nacimiento y sexo (o un registro corporal)';

  @override
  String get bodyTargetsNote =>
      'Para un día sin entrenar; los días de entreno suman ese ejercicio. Calorías: metabolismo basal × 1,2 + ejercicio, perder −20 % · ganar +10 %. Proteína: perder 2,2 g/kg (2,6 g/kg de masa magra si se conoce), mantener 1,6 g, ganar 2,0 g. Grasa: 25 % de las calorías. Hidratos: el resto. Solo orientativo, no es consejo médico.';

  @override
  String dayMacros(String carbs, String protein, String fat) {
    return 'Comido: HC $carbs · P $protein · G $fat g';
  }

  @override
  String dayMacrosVsTarget(
    String carbs,
    String carbsTarget,
    String protein,
    String proteinTarget,
    String fat,
    String fatTarget,
  ) {
    return 'HC $carbs/$carbsTarget · P $protein/$proteinTarget · G $fat/$fatTarget g';
  }

  @override
  String dayMacrosGoal(int kcal) {
    return 'Objetivos para $kcal kcal con el ejercicio de hoy — cambia el objetivo en Cuerpo';
  }

  @override
  String dayMacrosMissing(int n) {
    return 'No cuentan $n comidas sin macros';
  }

  @override
  String get partnerRoutinePlanning => 'Crear rutina juntos';

  @override
  String get partnerRoutineReadyTitle => 'Rutina compartida';

  @override
  String partnerRoutineProgress(int accepted, int total) {
    return '$accepted/$total confirmados';
  }

  @override
  String get partnerRoutineConfirm => 'Confirmar mi rutina';

  @override
  String get partnerRoutineConfirmed => 'Confirmado';

  @override
  String get partnerRoutineFinalized =>
      'Todos confirmaron. Añadida a tu entrenamiento.';

  @override
  String get partnerRoutineChanged =>
      'La rutina cambió. Revisa la última versión.';

  @override
  String get partnerRoutineEmpty => 'Añade al menos un ejercicio primero.';

  @override
  String get partnerRoutineStarted => 'La rutina ya está confirmada.';

  @override
  String get workoutImportTitle => 'Importar entrenamientos';

  @override
  String get workoutImportHint =>
      'Pega notas o añade archivos de texto y varias capturas. No se guarda nada antes de revisar.';

  @override
  String get workoutImportTextPlaceholder =>
      'Pega aquí tu historial de entrenamiento';

  @override
  String get workoutImportPaste => 'Pegar';

  @override
  String get workoutImportTextFiles => 'Archivos de texto';

  @override
  String get workoutImportScreenshots => 'Añadir capturas';

  @override
  String get workoutImportAnalyze => 'Crear vista previa';

  @override
  String get workoutImportEmpty => 'Añade texto o capturas primero.';

  @override
  String get workoutImportFailed =>
      'No se pudo leer. Tus fuentes siguen aquí; inténtalo de nuevo.';

  @override
  String get workoutImportReview =>
      'Revisa y edita fechas y ejercicios; luego guarda todo.';

  @override
  String get workoutImportMissingDate => 'Revisar fecha';

  @override
  String get workoutImportChooseDate => 'Elegir fecha';

  @override
  String get workoutImportUnparsed => 'Requiere revisión';

  @override
  String get workoutImportSave => 'Guardar todo';

  @override
  String get workoutImportAddExercise => 'Añadir ejercicio';

  @override
  String get workoutImportAddSet => 'Añadir serie';

  @override
  String get workoutImportRemove => 'Eliminar';

  @override
  String get workoutImportDuplicate =>
      'Puede que ya exista un entrenamiento similar';

  @override
  String get workoutImportTextLimit => 'Un lote admite hasta 6.000 caracteres.';

  @override
  String get workoutImportEditSources => 'Editar fuentes';

  @override
  String get workoutImportImageLimit => 'Añade hasta 5 capturas por lote.';

  @override
  String get workoutImportAiOff =>
      'La ayuda de IA está desactivada, así que no se puede leer el historial. Actívala en Ajustes › Ayuda de IA';

  @override
  String workoutImportPartial(int n) {
    return 'No se pudieron leer $n de las fuentes. Siguen ahí para corregirlas y reintentar.';
  }

  @override
  String get kakao => 'Kakao';

  @override
  String get signInChooseTitle => 'Elige cómo iniciar sesión';

  @override
  String get signInWithApple => 'Continuar con Apple';

  @override
  String get signInWithGoogle => 'Continuar con Google';

  @override
  String get signInWithKakao => 'Empezar con Kakao';

  @override
  String linkSignIn(String method) {
    return 'Vincular $method';
  }

  @override
  String get signInTaken =>
      'Este método de inicio de sesión ya está vinculado a otra cuenta.';

  @override
  String get tagOffline =>
      'No se pudo conectar con el gimnasio. Vuelve a acercar el teléfono cuando tengas señal.';

  @override
  String get handoffMine =>
      'Este es un registro que escribiste y enviaste. Ábrelo en el teléfono de quien lo recibe.';

  @override
  String get partnerErrFull =>
      'Está lleno. Nadie más puede unirse a esta sesión.';

  @override
  String get agentAlarmTitle => 'El resumen de hoy está listo';

  @override
  String agentAlarmBody(String gym) {
    return '$gym · Revisa el informe del agente';
  }

  @override
  String get agentAlarmChannel => 'Informe del agente';

  @override
  String get agentAlarmChannelDesc =>
      'Te avisa cuando el informe del entrenador está listo';

  @override
  String get updateRequired =>
      'Esta versión ya no puede conectarse al servidor. Actualiza la app; tus registros siguen en este dispositivo.';

  @override
  String get updateAction => 'Actualizar';

  @override
  String get shareGym => 'Compartido con tu entrenador';

  @override
  String get shareRejected =>
      'Tu gimnasio no aceptó este registro · Consúltalo con tu entrenador';

  @override
  String get shareMealsOnly =>
      'Solo las comidas se comparten con tu entrenador · Acerca tu teléfono a la pegatina del gimnasio para compartir el entrenamiento';

  @override
  String get shareNone =>
      'No se comparte con tu entrenador · Acerca tu teléfono a la pegatina del gimnasio para compartirlo';

  @override
  String get shareMealsSetting => 'Compartir comidas con mi entrenador';

  @override
  String shareMealsNote(String gym) {
    return 'Desde el día en que lo actives, tu entrenador de $gym también verá las comidas que registres los días que no vayas al gimnasio. Los registros de los días en que acercas el teléfono a la pegatina se comparten de todos modos.';
  }

  @override
  String get shareSend => 'Enviar a mi entrenador';

  @override
  String shareSendAsk(String gym) {
    return '¿Enviar esto a tu entrenador como el entrenamiento de hoy en $gym? También cuenta como asistencia.';
  }

  @override
  String get aiBusy =>
      'La IA está ocupada en este momento. Vuelve a intentarlo en un momento.';

  @override
  String get aiBudgetExhausted =>
      'Se agotó la capacidad de IA de hoy. Si estás en Wi-Fi, cambia a datos móviles e inténtalo de nuevo. Si no, podrás volver a usarla mañana.';

  @override
  String get accountSignOutEverywhere =>
      'Cerrar sesión en todos los dispositivos';

  @override
  String get accountSignOutEverywhereAsk =>
      'Se cerrará la sesión en los demás teléfonos y en la web. Este teléfono seguirá con la sesión iniciada.';

  @override
  String get accountSignOutEverywhereDone =>
      'Se cerró la sesión en todos los demás dispositivos.';

  @override
  String get accountSignOutEverywhereFailed =>
      'No se pudo cerrar la sesión en los otros dispositivos. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get storeUnreachable =>
      'No se pudo conectar con la tienda · Reintentar';

  @override
  String get ageConfirm => 'Tengo 14 años o más';

  @override
  String get ageConfirmAsk =>
      'Debes tener 14 años o más para unirte a un gimnasio. ¿Tienes 14 años o más?';

  @override
  String get gymClasses => 'Clases grupales';

  @override
  String get gymLeave => 'Salir de este gimnasio';

  @override
  String gymLeaveAsk(String gym) {
    return '¿Salir de $gym? Dejarás de recibir rutinas y tus entrenamientos y comidas ya no se compartirán. Se cancelan las reservas de PT y clases futuras; los registros anteriores y el historial de pagos se quedan en el gimnasio.';
  }

  @override
  String get gymNotices => 'Avisos';

  @override
  String passMembershipUntil(String date) {
    return 'Membresía hasta el $date';
  }

  @override
  String get passMembershipOn => 'Membresía activa';

  @override
  String get passMembershipPaused => 'Membresía en pausa';

  @override
  String passPtLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Quedan $n sesiones de PT',
      one: 'Queda 1 sesión de PT',
    );
    return '$_temp0';
  }

  @override
  String get passPtUnlimited => 'PT ilimitado';

  @override
  String get passPtPaused => 'PT en pausa';

  @override
  String passLocker(String label) {
    return 'Taquilla $label';
  }

  @override
  String passLockerUntil(String label, String date) {
    return 'Taquilla $label (hasta el $date)';
  }

  @override
  String get passNone => 'Sin bono activo';

  @override
  String get bookingRejected => 'Rechazada';

  @override
  String get bookingCancelled => 'Cancelada';

  @override
  String get bookingPaused =>
      'Tu bono de PT está en pausa. Pregunta a tu entrenador.';

  @override
  String newsBooked(String when) {
    return 'PT confirmada · $when';
  }

  @override
  String newsRejected(String when) {
    return 'Solicitud de PT rechazada · $when';
  }

  @override
  String newsCancelled(String when) {
    return 'PT cancelada · $when';
  }

  @override
  String newsMoved(String when) {
    return 'PT cambiada de hora · $when';
  }

  @override
  String newsTrainer(String trainer, String when) {
    return 'Cambio de entrenador de PT · $trainer · $when';
  }

  @override
  String newsAssigned(String trainer) {
    return 'Nuevo entrenador · $trainer';
  }

  @override
  String newsNotice(String title) {
    return 'Aviso · $title';
  }

  @override
  String newsMore(String news, int n) {
    return '$news y $n más';
  }

  @override
  String inviteFrom(String gym) {
    return '$gym te ha invitado';
  }

  @override
  String inviteBy(String name) {
    return 'Enviada por $name';
  }

  @override
  String get inviteAccept => 'Aceptar y unirme';

  @override
  String get inviteGone => 'Esta invitación ya no está disponible.';

  @override
  String get decline => 'Rechazar';

  @override
  String get gymConsentNotice =>
      'Si te unes, el propietario y los entrenadores de este gimnasio verán tu apodo, los entrenamientos que hagas aquí, las comidas que registres y tus reservas. La información que el gimnasio registra por su cuenta (notas, composición corporal, bonos y pagos) la gestiona el gimnasio. Si sales del gimnasio, se deja de compartir desde ese momento; los registros anteriores y el historial de pagos se quedan en el gimnasio.';

  @override
  String get joinAsk => '¿Solicitar unirte a este gimnasio?';

  @override
  String get joinAgree => 'Aceptar y solicitar';

  @override
  String get classesNone => 'No hay clases en las próximas dos semanas.';

  @override
  String get classesNotMember =>
      'Solo los miembros de este gimnasio pueden ver sus clases. Consulta tu membresía con el gimnasio.';

  @override
  String get gymUnverified => 'Gimnasio sin verificar';

  @override
  String classBook(int booked, int capacity) {
    return 'Reservar $booked/$capacity';
  }

  @override
  String classFull(int booked, int capacity) {
    return 'Completa $booked/$capacity';
  }

  @override
  String get classMine => 'Reservada · Cancelar';

  @override
  String get classCancelled => 'Cancelada';

  @override
  String get classCancelAsk => '¿Cancelar la reserva de esta clase?';

  @override
  String get trainerPtRequests => 'Solicitudes de PT';

  @override
  String get trainerApprove => 'Aprobar';

  @override
  String trainerRejectAsk(String member, String when) {
    return '¿Rechazar la solicitud de PT de $member para el $when?';
  }

  @override
  String get trainerApproved => 'Aprobada';

  @override
  String get trainerRejected => 'Rechazada';

  @override
  String trainerPendingCount(int n) {
    return '$n pendientes';
  }

  @override
  String get nicknameChange => 'Cambiar apodo';

  @override
  String get nicknameHelp =>
      'Es el nombre que ve tu gimnasio. Usa de 1 a 20 caracteres.';

  @override
  String get nicknameTaken => 'Ese apodo ya está en uso.';

  @override
  String get save => 'Guardar';

  @override
  String get gymLinkNotMember =>
      'Solo los miembros de este gimnasio pueden abrir esto.';

  @override
  String get ageConfirmFirst => 'Primero marca «Tengo 14 años o más».';

  @override
  String get noticeNew => 'Aviso nuevo';

  @override
  String get noticePinned => 'Fijado';

  @override
  String get refusedSignIn => 'Vuelve a iniciar sesión.';

  @override
  String get refusedGone => 'Esta reserva o clase ya no existe.';

  @override
  String get refusedBookingTime => 'Revisa la fecha y la hora de la reserva.';

  @override
  String get refusedBookingForbidden =>
      'No puedes hacer cambios en esta reserva.';

  @override
  String get refusedNoTrainer =>
      'Aún no tienes un entrenador asignado. Consulta con tu gimnasio.';

  @override
  String get refusedBookingChanged =>
      'Esta reserva ya se gestionó o ha cambiado.';

  @override
  String get refusedSlotTaken =>
      'Esa hora está cerrada o coincide con otra reserva.';

  @override
  String get refusedNoPass =>
      'Revisa el bono de PT: puede estar en pausa, vencido o agotado.';

  @override
  String get refusedTooLate => 'Esta sesión ya ha empezado.';

  @override
  String get refusedClassFull => 'Esta clase está completa.';

  @override
  String get refusedClassNoAccess =>
      'No tienes una membresía válida para el día de la clase. Consulta las fechas o la pausa con tu gimnasio.';

  @override
  String get refusedClassCancelled => 'Esta clase se canceló.';

  @override
  String get refusedAccountBlocked =>
      'Eres propietario o entrenador de un gimnasio. Sal del gimnasio o elimínalo y luego elimina tu cuenta.';

  @override
  String get firstRunHint1 =>
      'Escribe el nombre del ejercicio, por ejemplo Press de banca';

  @override
  String get firstRunHint2 =>
      'Luego escribe peso y repeticiones, como \"80 10\"';

  @override
  String get firstRunHint3 =>
      'Escribe \"tabata\" o \"60bpm\" para tener un temporizador';

  @override
  String get firstRunClose => 'Cerrar consejos';

  @override
  String get undo => 'Deshacer';

  @override
  String setRemoved(int n) {
    return 'Serie $n eliminada';
  }

  @override
  String get setDragHint =>
      'Suelta una serie en otra casilla para cambiar el orden';

  @override
  String get noteRemoved => 'Registro eliminado';

  @override
  String get shareSending =>
      'Enviando a tu entrenador · se enviará cuando haya señal';

  @override
  String get aiSettingNote =>
      'Si está activada, una IA en nuestro servidor lee el texto de ejercicios y comidas que escribes, las fotos de comidas y las preguntas sobre tus registros. Si la desactivas, no se envía nada a la IA y lo escrito queda tal cual.';

  @override
  String get nicknameLabel => 'Apodo';

  @override
  String get moreChips => 'Ver más';

  @override
  String get allExercises => 'Todos los registros';

  @override
  String routineWeekdayFactor(String day, String factor) {
    return '$day = $factor';
  }

  @override
  String routineDrift(String planned, String own) {
    return 'En el plan semanal este día es $planned, pero la última vez fue $own — copiarlo repite $own';
  }

  @override
  String get routineWeekendDetail =>
      'Fin de semana · lo que le falta a esta semana';

  @override
  String get routineClose => 'Cerrar';

  @override
  String routineDeviceExcluded(String list) {
    return 'Leído en el teléfono — sin: $list';
  }

  @override
  String routinePlateCost(String list) {
    return 'Usa discos (lo que se use): $list';
  }

  @override
  String routineEstimateNoFirst(int minutes) {
    return '~$minutes min · sin contar los nuevos';
  }

  @override
  String routineBpmChip(int bpm) {
    return 'Al ritmo de ${bpm}bpm';
  }

  @override
  String get routineSwap => 'Cambiar';

  @override
  String routineSwapTitle(String name) {
    return 'En lugar de $name: misma zona y equipo, hecho en los últimos 28 días';
  }

  @override
  String routineFirstPlan(String factor) {
    return 'Es la primera vez: sigue el plan semanal ($factor) · los números se llenan al registrar';
  }

  @override
  String routineFirstPlanWeekend(String factor) {
    return 'Es la primera vez: cubre lo que falta esta semana ($factor) · los números se llenan al registrar';
  }

  @override
  String routineDriftKept(String planned) {
    return 'En el plan semanal este día es $planned, pero ya cumpliste $planned esta semana — se mantiene el de la última vez';
  }

  @override
  String get routineAskTooName => 'Preguntar también';

  @override
  String get routineUnstart => 'Cancelar inicio';

  @override
  String get routineUnstartAsk =>
      'Este entrenamiento tiene series registradas. ¿Eliminarlo también?';

  @override
  String get partnerErrLeft =>
      'Las personas con las que entrenabas se han ido.';

  @override
  String get partnerErrBusy =>
      'Ya estás entrenando con alguien. Termina primero y vuelve a unirte.';

  @override
  String get partnerEndedGroup =>
      'El entrenamiento conjunto ha terminado. Tu registro se conserva.';

  @override
  String get partnerNotYours =>
      'No puedes cambiar una serie que registró otra persona. Es su registro.';

  @override
  String get partnerRoutinePlan => 'Convertir en rutina';

  @override
  String get partnerCodeHint =>
      'Introduce el código de seis caracteres que aparece en la pantalla de la otra persona.';

  @override
  String partnerPaste(String code) {
    return 'Pegar $code';
  }

  @override
  String get partnerShare => 'Compartir';

  @override
  String partnerShareText(String code) {
    return 'Código de setpad para entrenar juntos: $code\nEn la app: un registro → ⋯ → Entrenar juntos → Introducir código';
  }

  @override
  String partnerShareTextLink(String code, String url) {
    return 'Código de setpad para entrenar juntos: $code\nEn la app: un registro → ⋯ → Entrenar juntos → Introducir código, o únete ya con este enlace:\n$url';
  }

  @override
  String get partnerInviteMoreNew => 'Invitar a uno más · código nuevo';

  @override
  String get partnerHomeOpen => 'Abrir';

  @override
  String get togetherInviteSomeone => 'Alguien quiere hacerlo contigo';

  @override
  String get timerCollapse => 'Minimizar';

  @override
  String get timerCollapseA11y => 'Minimizar, el temporizador sigue en marcha';

  @override
  String get timerPaused => 'En pausa';

  @override
  String get timerResume => 'Reanudar';

  @override
  String get timerRestart => 'Desde el inicio';

  @override
  String get timerEnd => 'Terminar';

  @override
  String get timerHoldEnd => 'Mantén para terminar';

  @override
  String get timerHoldLeave => 'Mantén para salir';

  @override
  String get timerLock => 'Bloquear pantalla';

  @override
  String get timerUnlock => 'Desbloquear';

  @override
  String get timerLockHint => 'Toca dos veces para bloquear';

  @override
  String get timerUnlockHint => 'Toca dos veces para desbloquear';

  @override
  String get timerLockedHint => 'Mantén el candado 2 s para desbloquear';

  @override
  String get timerLockedAnnounce => 'Pantalla bloqueada';

  @override
  String get timerUnlockedAnnounce => 'Desbloqueada';

  @override
  String get timerSkipNext => 'Siguiente intervalo';

  @override
  String get timerSkipBack => 'Intervalo anterior';

  @override
  String get timerLastRound => 'Última ronda';

  @override
  String timerRoundShort(int n, int total) {
    return 'R $n/$total';
  }

  @override
  String timerNext(String items) {
    return 'Siguiente · $items';
  }

  @override
  String timerLeftTotal(String time) {
    return '$time restantes en total';
  }

  @override
  String timerElapsed(String time) {
    return 'Transcurrido $time';
  }

  @override
  String timerAboutLeft(String time) {
    return 'Quedan unos $time';
  }

  @override
  String get timerGo => '¡Ya!';

  @override
  String timerTarget(int target) {
    return '/ $target';
  }

  @override
  String timerBeatLine(String count) {
    return 'Pulso $count';
  }

  @override
  String timerBeatA11y(int n) {
    return 'Pulso $n';
  }

  @override
  String timerCountA11y(int count, int target) {
    return '$count de $target';
  }

  @override
  String timerRemainingA11y(String time) {
    return '$time restantes en este intervalo';
  }

  @override
  String get timerHeartShared =>
      'Juntos, la frecuencia cardíaca no corta el descanso';

  @override
  String get timerRestLog => 'Reps de esta ronda';

  @override
  String timerLogged(int n) {
    return 'Registrado: $n';
  }

  @override
  String get timerDone => '¡Listo!';

  @override
  String get timerStopped => 'Hasta aquí por ahora';

  @override
  String timerRoundsDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rondas',
      one: '1 ronda',
    );
    return '$_temp0';
  }

  @override
  String timerRepsDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reps',
      one: '1 rep',
    );
    return '$_temp0';
  }

  @override
  String timerRepsOfTarget(int n, int target) {
    return '$n / $target reps';
  }

  @override
  String get timerTotal => 'Total';

  @override
  String get timerTime => 'Tiempo';

  @override
  String get timerTempo => 'Tempo';

  @override
  String timerRoundChip(int n, String reps) {
    return 'R$n $reps';
  }

  @override
  String timerRoundCountTitle(int n) {
    return 'Reps de la ronda $n';
  }

  @override
  String timerFillRest(int n) {
    return 'Todas las rondas restantes: $n';
  }

  @override
  String get timerClear => 'Borrar';

  @override
  String get timerLogSets => 'Registrar como series';

  @override
  String timerLogSetsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Registrar $n series',
      one: 'Registrar 1 serie',
    );
    return '$_temp0';
  }

  @override
  String get timerAgain => 'Otra vez';

  @override
  String get timerClose => 'Cerrar';

  @override
  String timerLastRest(int from, int to) {
    return 'Último descanso ♥ $from → $to';
  }

  @override
  String timerSummaryTabata(int work, int rest, int rounds, String total) {
    return '$work s trabajo · $rest s descanso × $rounds · $total';
  }

  @override
  String timerTargetChip(int n) {
    return 'Meta $n';
  }

  @override
  String get timerNoTarget => 'Sin meta';

  @override
  String get timerOpen => 'Abrir';

  @override
  String timerDoneLine(int rounds, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rondas',
      one: '1 ronda',
    );
    return 'Completado · $_temp0 · $time';
  }

  @override
  String timerDoneBpmLine(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '1 rep',
    );
    return 'Completado · $_temp0 · $time';
  }

  @override
  String get timerLogNow => 'Registrar';

  @override
  String get timerTogether => 'Juntos';

  @override
  String get timerSwitchAsk =>
      '¿Detener el temporizador en marcha e iniciar este?';

  @override
  String get timerSwitchConfirm => 'Detener e iniciar';

  @override
  String timerUnloggedAsk(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hay $n rondas sin registrar',
      one: 'Hay 1 ronda sin registrar',
    );
    return '$_temp0';
  }

  @override
  String get timerLogFirst => 'Registrar primero';

  @override
  String get timerDiscardStart => 'Descartar e iniciar';

  @override
  String get timerActionFailed => 'No se envió · Reintentar';

  @override
  String get timerSheetTitle => 'Temporizador';

  @override
  String get timerAddChip => '+ Temporizador';

  @override
  String get timerTabata => 'Tabata';

  @override
  String get timerBeat => 'Metrónomo';

  @override
  String timerTotalLine(String time) {
    return 'Total $time';
  }

  @override
  String get timerHaptics => 'Vibración';

  @override
  String get timerHapticsSetting => 'Vibración del temporizador';

  @override
  String get timerReadOnly => 'Detén el temporizador para cambiarlo';

  @override
  String get timerNameNeeded => 'Primero escribe un nombre';

  @override
  String get timerWorkTitle => 'Tiempo de trabajo';

  @override
  String get timerRestTitle => 'Tiempo de descanso';

  @override
  String get timerRoundsTitle => 'Rondas';

  @override
  String get timerBpmTitle => 'Tempo (BPM)';

  @override
  String get timerTargetTitle => 'Reps objetivo';

  @override
  String timerSecondsValue(int n) {
    return '$n s';
  }

  @override
  String get timerMinValue => 'Es el mínimo';

  @override
  String get timerMaxValue => 'Es el máximo';

  @override
  String timerUnloggedReps(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hay $n repeticiones sin registrar',
      one: 'Hay 1 repetición sin registrar',
    );
    return '$_temp0';
  }

  @override
  String get focusOpen => 'Vista de entrenamiento';

  @override
  String focusExerciseOf(int n, int total) {
    return 'Ejercicio $n/$total';
  }

  @override
  String get focusPrevExercise => 'Ejercicio anterior';

  @override
  String get focusNextExerciseA11y => 'Siguiente ejercicio';

  @override
  String focusSetLabel(int n) {
    return 'Serie $n';
  }

  @override
  String get focusPlanned => 'Plan';

  @override
  String get focusLastTimeSame => 'Igual que la última vez';

  @override
  String get focusSameAsLast => 'Igual que la serie anterior';

  @override
  String get focusFromSetup => 'Según tu ajuste';

  @override
  String get focusPickValues => 'Elige el peso y las repeticiones';

  @override
  String get focusPickButton => 'Elegir peso y reps';

  @override
  String get focusPlanDone => 'Plan completado';

  @override
  String focusLastTimeLine(String set) {
    return 'Última vez aquí: $set';
  }

  @override
  String get focusBodyweight => 'Peso corporal';

  @override
  String get focusDone => 'Hecho';

  @override
  String get focusNextSetNow => 'Siguiente serie ya';

  @override
  String get focusStartRest => 'Empezar descanso';

  @override
  String focusNextUp(String set) {
    return 'Siguiente · $set';
  }

  @override
  String focusRestLength(String time) {
    return 'Descanso $time';
  }

  @override
  String focusRestPillA11y(String time) {
    return 'Quedan $time de descanso en otro ejercicio';
  }

  @override
  String get focusRestLess => '15 s menos de descanso';

  @override
  String get focusRestMore => '15 s más de descanso';

  @override
  String focusWeightUp(String step) {
    return 'Añadir $step';
  }

  @override
  String focusWeightDown(String step) {
    return 'Quitar $step';
  }

  @override
  String get focusRepsUp => 'Una repetición más';

  @override
  String get focusRepsDown => 'Una repetición menos';

  @override
  String get focusTodaySets => 'Series de hoy';

  @override
  String get focusExerciseDone => 'Terminar ejercicio';

  @override
  String focusNextExercise(String name) {
    return 'Siguiente: $name';
  }

  @override
  String get focusOneMore => 'Una serie más';

  @override
  String focusSummaryTitle(String name) {
    return '¡Terminaste $name!';
  }

  @override
  String get focusSets => 'Series';

  @override
  String get focusVolume => 'Volumen';

  @override
  String get focusTotalTime => 'Tiempo total';

  @override
  String get focusTotalDistance => 'Distancia total';

  @override
  String get focusTotalReps => 'Repeticiones';

  @override
  String get focusBest => 'Mejor';

  @override
  String focusLastTime(String when, String value) {
    return 'Última vez · $when · $value';
  }

  @override
  String get focusSame => 'Igual';

  @override
  String get focusUndo => 'Deshacer';

  @override
  String focusLogged(String set) {
    return 'Registrado $set';
  }

  @override
  String get focusHeartBack => 'Pulso recuperado · siguiente serie';

  @override
  String focusRestPill(String time) {
    return 'Descanso $time · Abrir';
  }

  @override
  String get focusSharedTimer => 'Temporizador compartido · Abrir';

  @override
  String get focusStartTimer => 'Iniciar temporizador';

  @override
  String focusHeroA11y(String set) {
    return '$set';
  }

  @override
  String focusRestA11y(String time) {
    return 'Quedan $time de descanso';
  }

  @override
  String get focusRestDefault => 'Descanso predeterminado entre series';

  @override
  String get focusRestTitle => 'Tiempo de descanso';

  @override
  String get focusWeightTitle => 'Peso';

  @override
  String get focusRepsTitle => 'Repeticiones';

  @override
  String get focusRestOverTitle => 'Fin del descanso';

  @override
  String get focusDistanceTitle => 'Distancia';

  @override
  String get focusPickTime => 'Elegir tiempo';

  @override
  String get focusPickDistance => 'Elegir distancia';
}
