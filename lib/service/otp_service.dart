import 'package:flutter/material.dart';
import 'package:otp_autofill/otp_autofill.dart';

/// Callback при инициализации.
typedef OtpInitializedCallback = void Function(
  OTPTextEditController controller,
);

/// Вспомогательный сервис для подстановки кодов из смс (для Android).
abstract class IOtpService {
  /// Инициализация сервиса.
  Future<void> init({
    OtpInitializedCallback? onInitialized,
    void Function(String code)? onCode,
    void Function(Object error)? onError,
    VoidCallback? onTimeOutException,
  });

  /// Освобождение ресурсов.
  void dispose();
}

/// Реализация [IOtpService].
class OtpService implements IOtpService {
  late final VoidCallback? _onTimeOutException;
  final _otpInteractor = OTPInteractor();
  final _regExp = RegExp(r'(\d{6})');
  OTPTextEditController? _otpTextEditController;

  @override
  Future<void> init({
    OtpInitializedCallback? onInitialized,
    void Function(String code)? onCode,
    void Function(Object error)? onError,
    VoidCallback? onTimeOutException,
  }) async {
    try {
      _onTimeOutException = onTimeOutException;
      await _otpInteractor.getAppSignature();

      _otpTextEditController = OTPTextEditController(
        codeLength: 6,
        onCodeReceive: onCode,
        otpInteractor: _otpInteractor,
        errorHandler: onError,
        onTimeOutException: _onTimeOutException,
      );

      onInitialized?.call(_otpTextEditController!);

      await _otpTextEditController!.startListenUserConsent(
        (code) {
          debugPrint('otp service - $code');
          return _regExp.stringMatch(code ?? '') ?? '';
        },
      );
    } on Object catch (e) {
      onError?.call(e);
    }
  }

  @override
  void dispose() {
    _otpInteractor.stopListenForCode();
    _otpTextEditController?.dispose();
  }
}
