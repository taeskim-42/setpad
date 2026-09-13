/// Grade the entire query meaning, including absent fields and extra requests.
/// Confirmation is reported separately; asking the user is not a correct parse.
List<String>? gradeRecordQuestion(
  Map<String, Object?> out,
  Map<String, Object?> expected,
) {
  if (expected.containsKey('note') ||
      (expected.containsKey('exercise') && expected['exercise'] == null)) {
    return null;
  }
  if (out.containsKey('error')) return ['error'];
  final errors = <String>[];
  final kind = expected['kind'] ?? 'answer';
  if (out['kind'] != kind) errors.add('kind');
  if ((out['rank'] == true) != (expected['rank'] == true)) errors.add('rank');
  if ((out['compare'] == true) != (expected['compare'] == true)) {
    errors.add('compare');
  }
  final requests = (out['requests'] as List?) ?? const [];
  if (kind == 'unsupported') {
    if (requests.isNotEmpty) errors.add('extra-requests');
    return errors;
  }
  final targets = expected['requests'] as List? ?? [expected];
  if (requests.length != targets.length) errors.add('request-count');
  for (var i = 0; i < targets.length && i < requests.length; i++) {
    final actual = requests[i] as Map;
    final target = targets[i] as Map;
    for (final key in [
      'exercise',
      'metric',
      'since',
      'until',
      'minWeight',
      'maxWeight',
      'minReps',
      'maxReps',
    ]) {
      if (actual[key] != target[key]) errors.add('$i.$key');
    }
    if (actual['unit'] != (target['unit'] ?? 'kg')) errors.add('$i.unit');
  }
  return errors;
}
