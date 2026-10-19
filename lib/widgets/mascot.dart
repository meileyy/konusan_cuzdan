import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../utils/theme.dart';

/// Cüzdan maskotunun duruşları (assets/images/maskot_*.png).
enum MascotPose {
  wave('maskot_selam'),
  shop('maskot_alisveris'),
  point('maskot_goster'),
  cheer('maskot_tebrik');

  const MascotPose(this.file);
  final String file;
  String get asset => 'assets/images/$file.png';
}

/// Konuşan maskot: yanında konuşma balonu vardır. Maskota veya balona
/// dokununca balondaki cümle (ya da [speech]) sesli okunur.
///
/// Maskot hafifçe aşağı yukarı süzülür; çocuğun dikkatini yönergeye çeker.
class MascotBubble extends StatefulWidget {
  const MascotBubble({
    super.key,
    required this.pose,
    required this.text,
    this.speech,
    this.size = 110,
    this.bubbleLeft = false,
  });

  final MascotPose pose;

  /// Balonda yazan kısa cümle.
  final String text;

  /// Sesli okunacak daha uzun yönerge (verilmezse [text] okunur).
  final String? speech;
  final double size;

  /// true ise balon maskotun soluna yerleşir.
  final bool bubbleLeft;

  @override
  State<MascotBubble> createState() => _MascotBubbleState();
}

class _MascotBubbleState extends State<MascotBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _speak() => context.read<AppState>().say(widget.speech ?? widget.text);

  @override
  Widget build(BuildContext context) {
    final mascot = AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -4 * Curves.easeInOut.transform(_float.value)),
        child: child,
      ),
      child: Image.asset(
        widget.pose.asset,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
    final bubble = Flexible(
      child: _SpeechBubble(text: widget.text, tailLeft: !widget.bubbleLeft),
    );
    return Semantics(
      button: true,
      label: widget.text,
      child: GestureDetector(
        onTap: _speak,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: widget.bubbleLeft
              ? [bubble, const SizedBox(width: 6), mascot]
              : [mascot, const SizedBox(width: 6), bubble],
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, required this.tailLeft});

  final String text;
  final bool tailLeft;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(tailLeft: tailLeft),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tailLeft ? 26 : 16,
          12,
          tailLeft ? 16 : 26,
          12,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: rounded(size: 20, weight: FontWeight.w800, height: 1.15),
        ),
      ),
    );
  }
}

/// Mavi kenarlı beyaz konuşma balonu ve maskota doğru küçük kuyruğu.
class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.tailLeft});

  final bool tailLeft;

  @override
  void paint(Canvas canvas, Size size) {
    const tail = 12.0;
    final left = tailLeft ? tail : 0.0;
    final right = tailLeft ? size.width : size.width - tail;
    final rect = RRect.fromLTRBR(
      left,
      0,
      right,
      size.height,
      const Radius.circular(22),
    );
    final cy = size.height * 0.6;
    final path = Path()..addRRect(rect);
    final tailPath = tailLeft
        ? (Path()
            ..moveTo(left + 2, cy - 10)
            ..lineTo(0, cy + 6)
            ..lineTo(left + 2, cy + 6)
            ..close())
        : (Path()
            ..moveTo(right - 2, cy - 10)
            ..lineTo(size.width, cy + 6)
            ..lineTo(right - 2, cy + 6)
            ..close());
    final shape = Path.combine(PathOperation.union, path, tailPath);

    canvas.drawShadow(shape, Colors.black26, 3, false);
    canvas.drawPath(shape, Paint()..color = Colors.white);
    canvas.drawPath(
      shape,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.tailLeft != tailLeft;
}
