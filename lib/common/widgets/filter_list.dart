import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/typedef.dart';

class FilterList<T> extends StatefulWidget {
  final bool disable;
  final List<Enum> items;
  final List<String> titles;
  final double horizontalPadding;
  final Func<Enum, void> onTap;
  const FilterList(
      {super.key,
      required this.disable,
      required this.items,
      required this.titles,
      this.horizontalPadding = AppSpacing.lg,
      required this.onTap})
      : assert(items.length == titles.length,
            "For each item there must be a title string");

  @override
  State<FilterList> createState() => _FilterListState();
}

class _FilterListState extends State<FilterList> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 30,
        child: ListView.separated(
          cacheExtent: 30,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          scrollDirection: Axis.horizontal,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(0.0),
              child: AppButton(
                width: null,
                fontSize: 14,
                intent: index == selectedIndex
                    ? AppButtonIntent.secondary
                    : AppButtonIntent.normal,
                size: AppButtonSize.small,
                style: AppButtonStyle.dropdown,
                onPressed: () {
                  if (widget.disable) return;
                  setState(() {
                    print("Updating index to ${widget.items[index]}");
                    selectedIndex = index;
                  });

                  widget.onTap(widget.items[index]);
                },
                child: Text(
                  widget.items[index].name.toString(),
                  style: TextStyle(
                      fontWeight: index == selectedIndex
                          ? FontWeight.bold
                          : FontWeight.w500),
                ),
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(
              width: 8,
            );
          },
        ));
  }
}
