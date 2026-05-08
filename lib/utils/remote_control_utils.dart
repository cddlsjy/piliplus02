import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 遥控器/键盘控制工具类
/// 提供遥控器按键判断、焦点高亮样式等通用功能
class RemoteControlUtils {
  RemoteControlUtils._();

  /// 判断按键是否为遥控器确认键 (Enter / Select / Numpad Enter)
  static bool isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.numpadEnter;
  }

  /// 判断按键是否为遥控器返回键 (Escape / Back / GoBack / BrowserBack)
  static bool isBackKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack;
  }

  /// 判断按键是否为方向键
  static bool isDirectionKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
  }

  /// 判断按键是否为媒体控制键
  static bool isMediaKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.mediaStop ||
        key == LogicalKeyboardKey.mediaTrackNext ||
        key == LogicalKeyboardKey.mediaTrackPrevious ||
        key == LogicalKeyboardKey.mediaFastForward ||
        key == LogicalKeyboardKey.mediaRewind;
  }

  /// 判断按键是否应被遥控器层拦截处理
  static bool shouldHandleByRemote(KeyEvent event) {
    final key = event.logicalKey;
    return isSelectKey(key) ||
        isBackKey(key) ||
        isDirectionKey(key) ||
        isMediaKey(key) ||
        key == LogicalKeyboardKey.tab;
  }

  /// 获取焦点高亮边框装饰
  static BoxDecoration focusedBorderDecoration({
    required ColorScheme colorScheme,
    double borderRadius = 12.0,
    double borderWidth = 2.5,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: colorScheme.primary,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// 获取焦点高亮缩放变换
  static Matrix4 focusedTransform({double scale = 1.02}) {
    return Matrix4.diagonal3Values(scale, scale, 1.0);
  }
}

/// 可聚焦卡片 Widget
/// 为任何可点击的卡片组件提供遥控器焦点高亮和 OK 键触发支持
///
/// 用法:
/// ```dart
/// FocusableCard(
///   onFocusChanged: (hasFocus) { ... },
///   child: Card(
///     child: InkWell(
///       onTap: () => print('tapped'),
///       child: ...,
///     ),
///   ),
/// )
/// ```
class FocusableCard extends StatefulWidget {
  const FocusableCard({
    super.key,
    required this.child,
    this.onFocusChanged,
    this.borderRadius = 12.0,
    this.autofocus = false,
    this.requestFocusOnTap = true,
  });

  /// 子组件
  final Widget child;

  /// 焦点变化回调
  final ValueChanged<bool>? onFocusChanged;

  /// 圆角半径
  final double borderRadius;

  /// 是否自动获取焦点
  final bool autofocus;

  /// 点击时是否请求焦点
  final bool requestFocusOnTap;

  @override
  State<FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends State<FocusableCard> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: _hasFocus
          ? RemoteControlUtils.focusedBorderDecoration(
              colorScheme: colorScheme,
              borderRadius: widget.borderRadius,
            )
          : null,
      transform: _hasFocus
          ? RemoteControlUtils.focusedTransform()
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: widget.child,
    );

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() => _hasFocus = hasFocus);
        widget.onFocusChanged?.call(hasFocus);
      },
      onKeyEvent: (node, event) {
        // 仅处理 KeyDown 时的确认键
        if (event is KeyDownEvent &&
            RemoteControlUtils.isSelectKey(event.logicalKey)) {
          // 模拟点击：找到子组件中的 InkWell/GestureDetector 并触发 onTap
          _simulateTap(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  /// 模拟点击事件
  void _simulateTap(BuildContext context) {
    // 通过触发 InkWell 的 onTap 来模拟点击
    // InkWell 在收到 Enter 键时会自动触发 onTap（如果有的话）
    // 但为了确保遥控器也能工作，我们通过 FocusNode 的方式触发
    final focusNode = Focus.maybeOf(context);
    if (focusNode != null && focusNode.hasPrimaryFocus) {
      // 让 Flutter 的 Focus 系统处理 Enter 键的默认行为
      // 这会自动触发 InkWell 的 onTap
      Actions.invoke(context, const ActivateIntent());
    }
  }
}

/// 可聚焦列表项 Widget
/// 专门为列表项（如历史记录、收藏等）提供遥控器支持
class FocusableListItem extends StatelessWidget {
  const FocusableListItem({
    super.key,
    required this.child,
    this.onFocusChanged,
    this.autofocus = false,
  });

  final Widget child;
  final ValueChanged<bool>? onFocusChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FocusableCard(
      autofocus: autofocus,
      borderRadius: 8.0,
      onFocusChanged: onFocusChanged,
      child: child,
    );
  }
}
