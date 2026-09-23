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
  String get reviewNumbers =>
      'Revisa los números y las condiciones antes de aplicar.';

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
  String get sameDayOther => 'Otros registros de este día';

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
}
