import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/painters/stripe_pattern_painter.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar(
      {super.key, required this.percentage, this.gradient = true});

  final double percentage;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    const int precision = 1000;
    final filled = ((percentage / 100) * precision).toInt().clamp(0, precision);
    final empty = (precision - filled).clamp(0, precision);
    final isLTR = Directionality.of(context) == TextDirection.ltr;
    final lightMode = Theme.of(context).brightness == Brightness.light;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 14,
            child: ClipRRect(
              // clipBehavior: Clip.none,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20), right: Radius.circular(20)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                        painter: StripePatternPainter(
                      bgColor: lightMode
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
                      stripeColor:
                          lightMode ? Colors.white : Colors.grey.shade700,
                      // stripeColor: Colors.red.withValues(alpha: 0.27),
                    )),
                  ),
                  Row(
                    children: [
                      if (filled != 0)
                        Expanded(
                          flex: filled,
                          child: ClipRRect(
                            clipBehavior: Clip.antiAlias,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(20),
                                right: Radius.circular(20)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                gradient: gradient
                                    ? LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: isLTR
                                            ? [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                              ]
                                            : [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                              ],
                                      )
                                    : null,
                              ),
                              child: const SizedBox(
                                height: 30,
                                // child: Placeholder(),
                              ),
                            ),
                          ),
                        ),
                      if (empty != 0)
                        Expanded(
                          flex: empty,
                          child: const SizedBox(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${(percentage.clamp(0, 100)).toStringAsFixed(0)}%",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ],
          ),
        )
      ],
    );
  }
}
