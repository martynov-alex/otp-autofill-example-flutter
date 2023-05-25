import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp_autofill_example/code_screen/code_confirm_wm.dart';

const _otpTextScaleFactor = 1.0;

final _emojiRegexp = RegExp(
  r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
);

/// Экран подтверждения авторизации.
class CodeConfirmScreen extends ElementaryWidget<ICodeConfirmWm> {
  /// @nodoc
  const CodeConfirmScreen({
    Key? key,
    WidgetModelFactory wmFactory = CodeConfirmWm.create,
  }) : super(wmFactory, key: key);

  @override
  Widget build(ICodeConfirmWm wm) {
    return Scaffold(
      body: Center(
        child: _OptCode(
          controllers: wm.codeFieldsControllers,
          otpLength: wm.otpLength,
          onCodeEntered: wm.submitCode,
        ),
      ),
    );
  }
}

/// Форма для ввода кода подтверждения
class _OptCode extends StatefulWidget {
  /// Контроллеры текстовых полей цифр кода.
  final List<TextEditingController> controllers;

  /// Длина кода.
  final int otpLength;

  /// Состояние ошибки ввода кода подтверждения
  final bool hasError;

  /// Обработчик окончания ввода кода подтверждения
  final ValueSetter<String> onCodeEntered;

  /// Обработчик изменения ввода кода подтверждения
  final ValueSetter<String>? onCodeChanged;

  /// Состояние обработки запроса подтверждения кода
  final bool isLoading;

  /// Является ли выполнение запроса успешным
  final bool isSuccess;

  const _OptCode({
    required this.controllers,
    required this.otpLength,
    required this.onCodeEntered,
    this.onCodeChanged,
    this.hasError = false,
    this.isLoading = false,
    this.isSuccess = false,
  });

  @override
  State<_OptCode> createState() => _OptCodeState();
}

/// Длина кода.
const otpLength = 6;

/// Символ пробела для ячейки кода.
const String zeroWidthChar = '\u200b';

const _inputItemWidth = 52.0;
const _inputItemHeight = 72.0;

class _OptCodeState extends State<_OptCode> {
  static const _firstItemIndex = 0;
  static const _codeContainerHeight = 200.0;
  static const _animationDuration = Duration(milliseconds: 300);
  static const _completeDelay = Duration(milliseconds: 500);

  late final int _lastItemIndex;
  late final List<FocusNode> _focusNodes;

  final TextInputFormatter _optCodeItemInputFormatter =
      TextInputFormatter.withFunction(
    (oldValue, newValue) {
      final value = newValue.text.length > 1
          ? newValue.replaced(const TextRange(start: 0, end: 1), '')
          : newValue;
      return value;
    },
  );

  bool _hasError = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _lastItemIndex = widget.otpLength - 1;
    _focusNodes = List<FocusNode>.unmodifiable(List<FocusNode>.generate(
      widget.otpLength,
      growable: false,
      (index) => FocusNode(),
    ));
  }

  @override
  void dispose() {
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(_OptCode oldWidget) {
    if (oldWidget.hasError != widget.hasError) {
      _hasError = widget.hasError;
      if (_hasError) {
        _resetState();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - _inputItemHeight / 2;
    final emptySpaceWidth =
        (width - otpLength * _inputItemWidth) / _lastItemIndex;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: SizedBox(
        height: _codeContainerHeight,
        child: Stack(
          children: List.generate(otpLength, (currentIndex) {
            const firstLine = _codeContainerHeight / 5 - _inputItemHeight / 2;
            const secondLine = _codeContainerHeight / 5;
            const thirdLine = _codeContainerHeight / 2;
            return AnimatedPositioned(
              duration: _animationDuration,
              curve: Curves.elasticInOut,
              top: currentIndex.isEven
                  ? firstLine
                  : currentIndex == 1
                      ? _isCompleted
                          ? firstLine
                          : thirdLine
                      : _isCompleted
                          ? firstLine
                          : secondLine,
              left: currentIndex *
                  (_inputItemWidth +
                      (emptySpaceWidth *
                          (currentIndex == _firstItemIndex ? 0 : 1))),
              child: _OptCodeInput(
                index: currentIndex,
                hasError: _hasError,
                autoFocus: currentIndex == 0,
                controller: widget.controllers[currentIndex],
                focusNode: _focusNodes[currentIndex],
                isLoading: widget.isLoading,
                onChanged: (value) => _onChangedHandler(value, currentIndex),
                onTap: () => _onTapHandler(currentIndex),
                formatters: [
                  _optCodeItemInputFormatter,
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  void _onChangedHandler(String value, int currentIndex) {
    // Переходим на предыдущий элемент при удаление значения из текущего поля
    // Не меняем фокус если текущий элемент является первым
    // также зачищаем поле от символа цифры и добавляем символ нулевой длины
    // для поддержки корректного удаления цифр
    if (currentIndex != _firstItemIndex && value.isEmpty) {
      _focusNodes[currentIndex - 1].requestFocus();
      widget.controllers[currentIndex - 1].text = zeroWidthChar;
      // Переходим на следующий элемент при вводе значение в текущие поле
      // Не меняем фокус если текущий элемент является последним
    } else if (currentIndex != _lastItemIndex && value.isNotEmpty) {
      _focusNodes[currentIndex + 1].requestFocus();
      if (currentIndex < _lastItemIndex) {
        // Добавляем символ нулевой длины в следующее поле (если отсутствует)
        // для поддержки перехода на предыдущий элемент при пустом значении
        final nextItemText = widget.controllers[currentIndex + 1].text;
        if (!nextItemText.contains(zeroWidthChar)) {
          widget.controllers[currentIndex + 1].text = zeroWidthChar;
        }
      }
    }

    // Теряем фокус и передаем итоговое значение если достигли конца
    // и все элементы имеют значение
    if (currentIndex == _lastItemIndex && _isAllFieldsFull()) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _isCompleted = true;
      });
      Future<void>.delayed(_completeDelay).whenComplete(
        () => widget.onCodeEntered(
          widget.controllers.map((controller) => controller.text).join(),
        ),
      );
    } else {
      widget.onCodeChanged?.call(widget.controllers
          .map((controller) => controller.text.replaceAll(zeroWidthChar, ''))
          .join());
    }

    // Выход из состояния ошибки если были сделаны изменения
    if (_hasError) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => setState(() {
          _hasError = false;
        }),
      );
    }
  }

  void _onTapHandler(int currentIndex) {
    final focusedItemIndex = _getFocusedItemIndex();
    // Предотвращает смену фокуса по нажатию на элемент
    if (currentIndex != _firstItemIndex) {
      if (focusedItemIndex != currentIndex) {
        _focusNodes[focusedItemIndex].requestFocus();
      }
    } else {
      if (widget.controllers[_firstItemIndex].text.isNotEmpty) {
        _focusNodes[focusedItemIndex].requestFocus();
      }
    }
  }

  void _resetState() {
    for (final controller in widget.controllers) {
      controller.text = zeroWidthChar;
    }
    _focusNodes[0].requestFocus();
    _isCompleted = false;
  }

  bool _isAllFieldsFull() {
    return widget.controllers.fold(
      true,
      (previousValue, element) => previousValue && element.text.isNotEmpty,
    );
  }

  int _getFocusedItemIndex() {
    return _focusNodes.indexOf(
      _focusNodes.firstWhere(
        (focus) => focus.hasFocus,
        orElse: () => _focusNodes[0],
      ),
    );
  }
}

class _OptCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final bool autoFocus;
  final FocusNode focusNode;
  final Function(String value) onChanged;
  final bool hasError;
  final VoidCallback? onTap;
  final bool isLoading;
  final int index;
  final List<TextInputFormatter>? formatters;

  const _OptCodeInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.formatters,
    this.autoFocus = false,
    this.hasError = false,
    this.isLoading = false,
    this.onTap,
    this.index = 0,
  });

  @override
  State<_OptCodeInput> createState() => _OptCodeInputState();
}

class _OptCodeInputState extends State<_OptCodeInput> {
  static const _placeholderWidth = 12.0;
  static const _placeholderHeight = 12.0;

  bool _isShowPlaceholder = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_inputTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_inputTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mqData = MediaQuery.of(context);

    // TODO(sukhov): переработать анимацию состояния загрузки
    // https://github.com/surfstudio/cyberdom-flutter/issues/69
    return widget.isLoading
        ? _CodeInputPlaceholder(
            text: widget.controller.text,
            index: widget.index,
          )
        : Stack(
            children: [
              SizedBox(
                width: _inputItemWidth,
                height: _inputItemHeight,
                child: MediaQuery(
                  data: mqData.copyWith(textScaleFactor: _otpTextScaleFactor),
                  child: TextField(
                    autofocus: widget.autoFocus,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    controller: widget.controller,
                    maxLength: 2,
                    focusNode: widget.focusNode,
                    cursorColor: Colors.black,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 68.0,
                      height: 1.059,
                    ),
                    onChanged: widget.onChanged,
                    enableInteractiveSelection: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(_emojiRegexp),
                      ...?widget.formatters,
                    ],
                    onTap: widget.onTap,
                  ),
                ),
              ),
              if (_isShowPlaceholder)
                Positioned(
                  top: _inputItemHeight / 2 - _placeholderHeight / 2,
                  left: _inputItemWidth - _placeholderWidth,
                  child: Container(
                    width: _placeholderWidth,
                    height: _placeholderHeight,
                    color: widget.hasError
                        ? Colors.red
                        : Colors.black.withOpacity(0.2),
                  ),
                ),
            ],
          );
  }

  void _inputTextChanged() {
    if (widget.controller.text.isNotEmpty &&
        widget.controller.text != zeroWidthChar) {
      setState(() {
        _isShowPlaceholder = false;
      });
    } else {
      setState(() {
        _isShowPlaceholder = true;
      });
    }
  }
}

class _CodeInputPlaceholder extends StatefulWidget {
  final String text;
  final int index;

  const _CodeInputPlaceholder({
    required this.text,
    required this.index,
    Key? key,
  }) : super(key: key);

  @override
  State<_CodeInputPlaceholder> createState() => __CodeInputPlaceholderState();
}

class __CodeInputPlaceholderState extends State<_CodeInputPlaceholder>
    with SingleTickerProviderStateMixin {
  static const int _animationDurationMs = 600;

  final Duration _duration = const Duration(milliseconds: _animationDurationMs);
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: _duration,
    );
    _colorAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.grey,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _animationController.repeat(reverse: true);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _inputItemWidth,
      height: _inputItemHeight,
      child: Center(
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (_, __) {
            return Text(
              widget.text,
              style: TextStyle(
                color: _colorAnimation.value,
                fontWeight: FontWeight.w300,
                fontSize: 42.0,
                height: 1,
              ),
              textScaleFactor: _otpTextScaleFactor,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
