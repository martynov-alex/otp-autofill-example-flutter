import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:otp_autofill_example/code_screen/code_confirm_model.dart';
import 'package:otp_autofill_example/service/otp_service.dart';

import 'code_confirm_screen.dart';

/// Длина OTP кода.
const _otpLength = 6;

CodeConfirmWm _create(BuildContext context) {
  final model = CodeConfirmModel(TestErrorHandler());

  return CodeConfirmWm(
    model,
    otpService: OtpService(),
  );
}

/// Интерфейс Wm экрана подтверждения авторизации.
abstract class ICodeConfirmWm extends IWidgetModel {
  /// Контроллеры текстовых полей цифр кода.
  List<TextEditingController> get codeFieldsControllers;

  /// Длина OTP кода.
  int get otpLength;

  /// Отправка запроса на подтверждение авторизации.
  void submitCode(String code);
}

/// Реализация [ICodeConfirmWm].
class CodeConfirmWm extends WidgetModel<CodeConfirmScreen, ICodeConfirmModel>
    implements ICodeConfirmWm {
  @override
  final codeFieldsControllers =
      List.unmodifiable(List<TextEditingController>.generate(
    _otpLength,
    growable: false,
    (index) => TextEditingController(text: zeroWidthChar),
  ));

  final IOtpService _otpService;

  @override
  int get otpLength => _otpLength;

  /// @nodoc
  CodeConfirmWm(
    ICodeConfirmModel model, {
    required IOtpService otpService,
  })  : _otpService = otpService,
        super(model);

  /// Фабрика.
  factory CodeConfirmWm.create(BuildContext context) => _create(context);

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _otpService.init(onCode: _onOtpCode);
  }

  @override
  void dispose() {
    for (final controller in codeFieldsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void submitCode(String code) {
    FocusManager.instance.primaryFocus?.unfocus();
    debugPrint(code);
  }

  void _onOtpCode(String code) {
    debugPrint(code);

    for (var index = 0; index < otpLength; index++) {
      codeFieldsControllers[index].text = code[index];
    }
    submitCode(code);
  }
}

class TestErrorHandler implements ErrorHandler {
  @override
  void handleError(Object error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      print(error);
      print(stackTrace);
    }
  }
}
