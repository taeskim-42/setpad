// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LZh extends L {
  LZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '今日训练';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get howTo => '输入动作名称后按 Enter → 输入组数后按 Enter → 空行按 Enter 换下一个动作';

  @override
  String get exerciseNameHint => '动作名称';

  @override
  String get repeatPrevious => '同上一组';

  @override
  String get addSet => '添加组';

  @override
  String get numberKeypad => '数字键盘';

  @override
  String setOrdinal(int n) {
    return '第$n组';
  }

  @override
  String repsCount(int n) {
    return '$n次';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class LZhHans extends LZh {
  LZhHans() : super('zh_Hans');

  @override
  String get appTitle => '今日训练';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get howTo => '输入动作名称后按 Enter → 输入组数后按 Enter → 空行按 Enter 换下一个动作';

  @override
  String get exerciseNameHint => '动作名称';

  @override
  String get repeatPrevious => '同上一组';

  @override
  String get addSet => '添加组';

  @override
  String get numberKeypad => '数字键盘';

  @override
  String setOrdinal(int n) {
    return '第$n组';
  }

  @override
  String repsCount(int n) {
    return '$n次';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class LZhHant extends LZh {
  LZhHant() : super('zh_Hant');

  @override
  String get appTitle => '今日訓練';

  @override
  String get copy => '複製';

  @override
  String get copied => '已複製';

  @override
  String get howTo => '輸入動作名稱後按 Enter → 輸入組數後按 Enter → 空行按 Enter 換下一個動作';

  @override
  String get exerciseNameHint => '動作名稱';

  @override
  String get repeatPrevious => '同上一組';

  @override
  String get addSet => '新增組';

  @override
  String get numberKeypad => '數字鍵盤';

  @override
  String setOrdinal(int n) {
    return '第$n組';
  }

  @override
  String repsCount(int n) {
    return '$n次';
  }
}
