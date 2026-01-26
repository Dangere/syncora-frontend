import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/typedef.dart';

class FilterListItem {
  final Enum value;
  final List<Enum> opposites;
  final String title;
  FilterListItem(
      {required this.value, required this.title, this.opposites = const []});
}

// A widget that displays a list of filters that can be single or multi selected
class FilterList extends StatefulWidget {
  final bool disable;
  final bool multiSelect;
  final List<FilterListItem> items;
  final double horizontalPadding;
  final Func<List<Enum>, void> onTap;
  const FilterList(
      {super.key,
      required this.disable,
      this.multiSelect = false,
      required this.items,
      this.horizontalPadding = AppSpacing.lg,
      required this.onTap});

  @override
  State<FilterList> createState() => _FilterListState();
}

class _FilterListState extends State<FilterList> {
  // int selectedIndex = 0;

  List<Enum> selectedValues = List.empty(growable: true);

  void _onSelect(FilterListItem item) {
    if (widget.disable) return;
    setState(() {
      if (widget.multiSelect) {
        if (selectedValues.contains(item.value)) {
          if (selectedValues.length == 1) return;
          selectedValues.remove(item.value);
        } else {
          selectedValues.add(item.value);
        }

        for (var i = 0; i < item.opposites.length; i++) {
          selectedValues.remove(item.opposites[i]);
        }

        widget.onTap(selectedValues);
      } else {
        selectedValues = [item.value];
        widget.onTap(selectedValues);
      }
    });
  }

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
            bool isSelected =
                selectedValues.contains(widget.items[index].value);
            return Padding(
              padding: const EdgeInsets.all(0.0),
              child: AppButton(
                width: null,
                fontSize: 14,
                intent: isSelected
                    ? AppButtonIntent.secondary
                    : AppButtonIntent.normal,
                size: AppButtonSize.small,
                style: AppButtonStyle.dropdown,
                onPressed: () => _onSelect(widget.items[index]),
                child: Text(
                  widget.items[index].title.toString(),
                  style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500),
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
