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
  String get howTo => 'Busca un ejercicio y registra tus series.';

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
}
