library flutter_progress;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'tal_progress_indicator.dart';

enum ProgressType {
  line,
  circle,
}

class Progress extends StatefulWidget {
  /// 设置环形进度条宽高，例如：Size.square(100)
  final Size size;

  /// 进度条类型，线型（ProgressType.line）、圆形（ProgressType.circle）
  final ProgressType type;

  /// 百分比 0-100，不传则表示模糊进度（循环动画）
  final double percent;

  /// 进度条的色彩
  ///
  final Color strokeColor;

  /// 设置进度条为渐变多种色彩，颜色数量至少为 2
  ///
  /// 注：如果进度条 percent 为 null，则颜色有循环动画效果
  final List<Color> colors;

  /// 未完成的分段的颜色
  final Color trailColor;

  /// 是否显示进度数值或状态图标
  final bool showInfo;

  /// info 自定义方法
  final Widget Function(double percent) infoBuilder;

  /// 进度条宽度
  final double strokeWidth;

  const Progress({
    Key key,
    this.type = ProgressType.line,
    this.size = const Size.square(100),
    this.percent,
    this.strokeColor,
    this.trailColor,
    this.colors,
    this.showInfo = true,
    this.infoBuilder,
    this.strokeWidth = 4.0,
  })  : assert(percent == null || (percent >= 0 && percent <= 100)),
        assert(strokeWidth == null || strokeWidth > 0),
        super(key: key);
  @override
  _ProgressState createState() => _ProgressState();
}

class _ProgressState extends State<Progress> with TickerProviderStateMixin {
  AnimationController animationController;
  AnimationController percentAnimationController;
  Animation percentAnimation;
  double percent;
  Function percentListener;

  @override
  void dispose() {
    super.dispose();
    animationController?.dispose();
    percentAnimationController?.dispose();
  }

  @override
  void didUpdateWidget(covariant Progress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent &&
        percentAnimationController != null) {
      if (percentAnimation != null) {
        percentAnimation.removeListener(percentListener);
      }

      /// reset 会触发 listener，所以 removeListener 放在上方
      percentAnimationController.reset();
      percentAnimation = Tween(
        begin: oldWidget.percent,
        end: widget.percent,
      ).animate(CurvedAnimation(
        parent: percentAnimationController,
        curve: Curves.easeInOutSine,
      ));
      percentAnimation.addListener(percentListener);
      percentAnimationController.forward();
    }
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      percent = widget.percent;
    });

    percentListener = () {
      if (percentAnimation != null) {
        setState(() {
          percent = percentAnimation.value;
        });
      }
    };

    percentAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    /// FIXME: 这里有个极其稀少的场景是如果 colors 后续传值了，就不会初始化 AnimationController 了，会导致 bug
    if (widget.colors != null) {
      animationController = AnimationController(
        duration: Duration(
          seconds: 1,
          milliseconds: 500,
        ),
        vsync: this,
      );
      animationController.repeat(
        reverse: true,
      );
    }
  }

  /// colors 如果不为 null，则取数组的第一项和最后一项颜色进行循环动画过渡
  /// 如果为 null，则为单色进度条，此时可以通过 strokeColor 来设置进度条色彩
  Animation<Color> _getValueColor() {
    return widget.colors != null
        ? animationController.drive(
            ColorTween(
              begin: widget.colors.first,
              end: widget.colors.last,
            ),
          )
        : widget.strokeColor != null
            ? AlwaysStoppedAnimation(widget.strokeColor)
            : null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.type == ProgressType.line
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _TalLinearProgressIndicator(
                  minHeight: widget.strokeWidth,
                  value: percent == null ? null : percent / 100,
                  backgroundColor: widget.trailColor,

                  /// 这里的 colors 传值会导致进度条为渐变色，优先级高于 valueColor
                  /// 但是模糊进度条我们需要的是持续的色彩过渡效果
                  /// 所以这里在模糊进度条下就不传 colors 的值
                  colors: percent != null ? widget.colors : null,
                  valueColor: _getValueColor(),
                ),
              ),
              widget.infoBuilder != null
                  ? widget.infoBuilder(percent)
                  : SizedBox.shrink(),
              widget.showInfo && percent != null && widget.infoBuilder == null
                  ? Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          )
        : Padding(
            padding: EdgeInsets.all(
              widget.strokeWidth / 2,
            ),
            child: SizedBox(
              width: widget.size.width - (widget.strokeWidth),
              height: widget.size.height - (widget.strokeWidth),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _TalCircularProgressIndicator(
                      /// 这里的 colors 传值会导致进度条为渐变色，优先级高于 valueColor
                      /// 但是模糊进度条我们需要的是持续的色彩过渡效果
                      /// 所以这里在模糊进度条下就不传 colors 的值
                      colors: percent != null ? widget.colors : null,
                      backgroundColor: widget.trailColor,
                      strokeWidth: widget.strokeWidth,
                      value: percent == null ? null : percent / 100,
                      valueColor: _getValueColor(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        widget.infoBuilder != null
                            ? widget.infoBuilder(percent)
                            : SizedBox.shrink(),
                        widget.showInfo &&
                                percent != null &&
                                widget.infoBuilder == null
                            ? Text(
                                '${percent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1,
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
