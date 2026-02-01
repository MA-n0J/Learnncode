import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart';

class AnimatedBtn extends StatefulWidget {
  const AnimatedBtn({
    super.key,
    required RiveAnimationController btnAnimationController,
    required this.press,
    this.onAnimationComplete,
  }) : _btnAnimationController = btnAnimationController;

  final RiveAnimationController _btnAnimationController;
  final VoidCallback press;
  final VoidCallback? onAnimationComplete;

  @override
  State<AnimatedBtn> createState() => _AnimatedBtnState();
}

class _AnimatedBtnState extends State<AnimatedBtn> {
  @override
  void initState() {
    super.initState();
    // Listen for animation completion
    widget._btnAnimationController.isActiveChanged
        .addListener(_onAnimationStateChanged);
  }

  void _onAnimationStateChanged() {
    debugPrint(
        "Animation isActive: ${widget._btnAnimationController.isActive}");
    if (!widget._btnAnimationController.isActive) {
      debugPrint("Animation completed, calling onAnimationComplete");
      widget.onAnimationComplete?.call();
    }
  }

  @override
  void dispose() {
    // Remove the listener to prevent memory leaks
    widget._btnAnimationController.isActiveChanged
        .removeListener(_onAnimationStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.press,
      child: SizedBox(
        height: 64,
        width: 260,
        child: Stack(
          children: [
            RiveAnimation.asset(
              "assets/RiveAssets/button.riv",
              controllers: [widget._btnAnimationController],
            ),
            const Positioned.fill(
              top: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.arrow_right),
                  SizedBox(width: 8),
                  Text(
                    "Start now",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
