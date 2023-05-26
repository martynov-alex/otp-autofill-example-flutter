/// Регулярные выражения приложения.
class AppRegexps {
  /// Регулярное выражение для emoji символов.
  ///
  /// Регулярное выражение взято отсюда - https://ihateregex.io/expr/emoji/.
  /// Если часть новых emoji на iOS устройствах не будет "отлавливаться", то
  /// взять данное - https://github.com/mathiasbynens/emoji-regex/blob/main/index.js.
  static final RegExp emojiRegexp = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
  );

  /// Цифры.
  static final RegExp _digitsRegexp = RegExp('[0-9]');

  /// Регулярное выражение кода подтверждения.
  static final RegExp _codeRegexp = RegExp('^[0-9]{6}');

  /// Проверяет является ли [code] валидным кодом подтверждения.
  static bool isCodeValid(String code) {
    return _codeRegexp.hasMatch(code);
  }

  /// Проверяет является ли символ цифрой.
  static bool isDigit(String value) {
    return _digitsRegexp.hasMatch(value);
  }
}
