import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Экрани телефон.
bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < 600;

/// Матн бо градиенти тиллоӣ.
class GoldText extends StatelessWidget {
  const GoldText(this.text, {super.key, required this.style, this.textAlign, this.maxLines});
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: Gold.textGradient.createShader,
    child: Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: TextOverflow.ellipsis),
  );
}

/// Иконка бо градиенти тиллоӣ.
class GoldIcon extends StatelessWidget {
  const GoldIcon(this.icon, {super.key, this.size = 24});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: Gold.textGradient.createShader,
    child: Icon(icon, size: size),
  );
}

/// Матни тиллоӣ бо дурахши ҳаракаткунанда (сарлавҳаи асосӣ).
class ShimmerGoldText extends StatefulWidget {
  const ShimmerGoldText(this.text, {super.key, required this.style, this.textAlign});
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  State<ShimmerGoldText> createState() => _ShimmerGoldTextState();
}

class _ShimmerGoldTextState extends State<ShimmerGoldText> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Дурахш як бор, баъд ҳар 7 сония — дар байн ҳеҷ кадр кашида намешавад.
    _c.forward();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) => _c.forward(from: 0));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Gold.dark
        ? const [Gold.deep, Gold.gold, Color(0xFFFFF6D8), Gold.gold, Gold.deep]
        : const [Color(0xFF6B4E0C), Color(0xFFA67C1B), Color(0xFFE2C26A), Color(0xFFA67C1B), Color(0xFF6B4E0C)];
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final x = _c.value * 3 - 1;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment(x - 1, -.3),
              end: Alignment(x + 1, .3),
              colors: colors,
              stops: const [0, .35, .5, .65, 1],
            ).createShader(r),
            child: child,
          );
        },
        child: Text(widget.text, style: widget.style, textAlign: widget.textAlign),
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: Gold.gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Gold.gold.withValues(alpha: Gold.dark ? .25 : .35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 22, vertical: compact ? 10 : 14),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Gold.onGold),
                    )
                  else if (icon != null)
                    Icon(icon, size: 20, color: Gold.onGold),
                  if (loading || icon != null) const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Gold.onGold, fontWeight: FontWeight.w700, letterSpacing: .3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: Gold.dark ? Gold.light : Gold.text,
      backgroundColor: Gold.dark ? null : Gold.surface,
      side: BorderSide(color: Gold.dark ? Gold.deep : Gold.line),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: expand ? const Size.fromHeight(48) : null,
    );
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18, color: Gold.accent),
            label: Text(label),
          );
  }
}

/// Тугмаи мудаввар бо иконка.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 44,
    this.child,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: Gold.surface,
        side: BorderSide(color: Gold.line),
      ),
      icon: child ?? Icon(icon, size: size * .45, color: color ?? Gold.text),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 14 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: compact ? 18 : 26, height: 1.5, color: Gold.accent),
                    const SizedBox(width: 10),
                    Flexible(child: Text(title, style: Gold.display(compact ? 26 : 32))),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(color: Gold.muted, fontSize: compact ? 13 : 14),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

IconData categoryIcon(String slug) => switch (slug) {
  'rings' => Icons.radio_button_unchecked,
  'earrings' => Icons.water_drop_outlined,
  'chains' => Icons.link,
  'pendants' => Icons.favorite_border,
  'bracelets' => Icons.all_inclusive,
  'sets' => Icons.auto_awesome_outlined,
  'wedding' => Icons.join_inner,
  'watches' => Icons.watch_outlined,
  'bullion' => Icons.view_agenda_outlined,
  'gems' => Icons.diamond_outlined,
  'silver' => Icons.brightness_5_outlined,
  'antique' => Icons.museum_outlined,
  _ => Icons.diamond_outlined,
};

Color stoneColor(String stone) => switch (stone) {
  'diamond' => const Color(0xFF9EC9F0),
  'emerald' => const Color(0xFF2FBF71),
  'ruby' => const Color(0xFFE0245E),
  'sapphire' => const Color(0xFF2D6BE4),
  'spinel' => const Color(0xFFFF4F7B),
  'pearl' => const Color(0xFFD9CBB4),
  'topaz' => const Color(0xFF6CC7F0),
  'zirconia' => const Color(0xFFB9C3F5),
  _ => Gold.gold,
};

/// Расм барои эълонҳои бе сурат: дурахш + иконкаи категория дар ранги металл.
class JewelArt extends StatelessWidget {
  const JewelArt({super.key, required this.category, required this.stone, required this.metal, this.seed = 0});
  final String category;
  final String stone;
  final String metal;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final silvery = metal == 'white_gold' || metal == 'platinum' || metal == 'silver';
    final rose = metal == 'rose_gold';
    final accent = stoneColor(stone);
    final angle = (seed % 7) * math.pi / 7;
    final metalGradient = silvery
        ? (Gold.dark
              ? const LinearGradient(colors: [Color(0xFF8E9399), Color(0xFFF4F6F8), Color(0xFFB9BEC4)])
              : const LinearGradient(colors: [Color(0xFF6D737B), Color(0xFFC9CED4), Color(0xFF878D95)]))
        : rose
        ? const LinearGradient(colors: [Color(0xFFA9604C), Color(0xFFF1BFA9), Color(0xFFB97A63)])
        : Gold.dark
        ? Gold.gradient
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9A7316), Color(0xFFE6C463), Color(0xFFB8892A)],
          );
    final bgColors = Gold.dark
        ? [accent.withValues(alpha: .22), Gold.surface2, Gold.bg]
        : [accent.withValues(alpha: .13), const Color(0xFFF9F4EA), const Color(0xFFEFE6D4)];
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(math.cos(angle) * .4, -.3),
          radius: 1.1,
          colors: bgColors,
          stops: const [0, .55, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _SparklePainter(seed, accent, Gold.dark ? Gold.light : const Color(0xFFC9A13B))),
          Center(
            child: FractionallySizedBox(
              widthFactor: .42,
              heightFactor: .42,
              child: FittedBox(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: metalGradient.createShader,
                  child: Icon(categoryIcon(category), size: 100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.seed, this.color, this.sparkle);
  final int seed;
  final Color color;
  final Color sparkle;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final p = Paint();
    for (var i = 0; i < 9; i++) {
      final c = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final r = 1.5 + rnd.nextDouble() * 3.5;
      final path = Path()
        ..moveTo(c.dx, c.dy - r * 2)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2);
      canvas.drawPath(path, p..color = (i.isEven ? sparkle : color).withValues(alpha: .25 + rnd.nextDouble() * .5));
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.seed != seed || old.color != color || old.sparkle != sparkle;
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.icon, this.gold = false});
  final String label;
  final IconData? icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final fg = gold ? Gold.onGold : Gold.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: gold ? Gold.gradient : null,
        color: gold ? null : Gold.surface.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(20),
        border: gold ? null : Border.all(color: Gold.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: gold ? Gold.onGold : Gold.accent),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.text, this.action});
  final IconData icon;
  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: Gold.surface2, shape: BoxShape.circle),
            child: Center(child: GoldIcon(icon, size: 40)),
          ),
          const SizedBox(height: 18),
          Text(title, style: Gold.display(26), textAlign: TextAlign.center),
          if (text != null) ...[
            const SizedBox(height: 8),
            Text(
              text!,
              style: TextStyle(color: Gold.muted),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

/// Маҳдудкунандаи паҳнӣ барои экранҳои калон.
class Constrained extends StatelessWidget {
  const Constrained({super.key, required this.child, this.maxWidth = 1240, this.padding});
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: padding ?? EdgeInsets.symmetric(horizontal: isCompact(context) ? 16 : 28),
        child: child,
      ),
    ),
  );
}

/// Корт бо сояи нарм (равшан) ё хати борик (торик).
BoxDecoration cardDecoration({double radius = 18, Color? border}) => BoxDecoration(
  color: Gold.surface,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: border ?? Gold.line),
  boxShadow: Gold.softShadow,
);
