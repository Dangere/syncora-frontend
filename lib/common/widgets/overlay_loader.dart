import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

class OverlayLoader extends StatefulWidget {
  const OverlayLoader({
    super.key,
    required this.isLoading,
    required this.overlay,
    required this.body,
  });

  final Widget body;
  final Widget overlay;
  final bool isLoading;

  @override
  State<OverlayLoader> createState() => _OverlayLoaderState();
}

class _OverlayLoaderState extends State<OverlayLoader> {
  Widget overlay() {
    FocusScope.of(context).unfocus();
    return AbsorbPointer(
      child: Center(child: widget.overlay),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.body,
      if (widget.isLoading) overlay(),
    ]);
  }
}
