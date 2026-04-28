import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tv_theme.dart';

/// مدير الفوكس للتلفزيون - يتحكم في D-Pad navigation
class TvFocusManager {
  TvFocusManager._();

  // ─── مفتاح للتنقل العالمي ────────────────────────────────────
  static final Map<String, FocusNode> _nodes = {};

  /// إنشاء أو استرجاع FocusNode باسم مخصص
  static FocusNode get(String key) {
    return _nodes.putIfAbsent(key, () => FocusNode(debugLabel: key));
  }

  /// التركيز على عقدة بالاسم
  static void focus(String key, {BuildContext? context}) {
    final node = _nodes[key];
    if (node != null && node.canRequestFocus) {
      node.requestFocus();
    }
  }

  /// تحرير جميع FocusNodes المرتبطة بمفاتيح محددة
  static void dispose(List<String> keys) {
    for (final key in keys) {
      _nodes[key]?.dispose();
      _nodes.remove(key);
    }
  }

  /// تحرير جميع FocusNodes
  static void disposeAll() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    _nodes.clear();
  }
}

/// Widget يجعل ابنه قابلاً للتحديد بالريموت مع تأثيرات بصرية
class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final VoidCallback? onFocusGained;
  final VoidCallback? onFocusLost;
  final FocusNode? focusNode;
  final bool autofocus;
  final double focusScale;
  final BorderRadius? borderRadius;

  const TvFocusable({
    super.key,
    required this.child,
    this.onSelect,
    this.onFocusGained,
    this.onFocusLost,
    this.focusNode,
    this.autofocus = false,
    this.focusScale = 1.05,
    this.borderRadius,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _scaleController;
  late final Animation<double> _scale;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.focusScale).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  void _onFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused != _isFocused) {
      setState(() => _isFocused = focused);
      if (focused) {
        _scaleController.forward();
        widget.onFocusGained?.call();
      } else {
        _scaleController.reverse();
        widget.onFocusLost?.call();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onSelect?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                border: Border.all(
                  color: _isFocused
                      ? TvTheme.focusBorder
                      : Colors.transparent,
                  width: TvTheme.focusBorderWidth,
                ),
                boxShadow: _isFocused
                    ? [
                        const BoxShadow(
                          color: TvTheme.focusGlow,
                          blurRadius: 24,
                          spreadRadius: 8,
                          offset: Offset(0, 10),
                        )
                      ]
                    : [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
