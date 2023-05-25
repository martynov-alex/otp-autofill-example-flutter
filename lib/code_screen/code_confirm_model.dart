import 'package:elementary/elementary.dart';

/// Интерфейс модели экрана подтверждения авторизации.
abstract class ICodeConfirmModel extends ElementaryModel {}

/// Реализация [ICodeConfirmModel].
class CodeConfirmModel extends ElementaryModel implements ICodeConfirmModel {
  /// @nodoc
  CodeConfirmModel(ErrorHandler errorHandler)
      : super(errorHandler: errorHandler);
}
