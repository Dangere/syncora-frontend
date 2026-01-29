import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/typedef.dart';

class FilterListItem<T extends Enum> {
  final T value;
  final List<T> opposites;
  final String title;
  final AsyncFunc<T, int?>? countFactory;
  FilterListItem(
      {required this.value,
      required this.title,
      this.opposites = const [],
      this.countFactory});
}

// A widget that displays a list of filters that can be single or multi selected
class FilterList<T extends Enum> extends StatefulWidget {
  final bool disable;
  final bool multiSelect;
  final List<FilterListItem<T>> items;
  final double horizontalPadding;
  final Func<List<T>, void> onTap;
  const FilterList(
      {super.key,
      required this.disable,
      this.multiSelect = false,
      required this.items,
      this.horizontalPadding = AppSpacing.lg,
      required this.onTap});

  @override
  State<FilterList<T>> createState() => _FilterListState<T>();
}

class _FilterListState<T extends Enum> extends State<FilterList<T>> {
  // int selectedIndex = 0;

  List<T> selectedValues = List.empty(growable: true);

  void _onSelect(FilterListItem<T> item) {
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
            return AppButton(
              ignoreContentPadding: true,
              width: null,
              fontSize: 14,
              intent: isSelected
                  ? AppButtonIntent.secondary
                  : AppButtonIntent.normal,
              size: AppButtonSize.small,
              style: AppButtonStyle.dropdown,
              onPressed: () => _onSelect(widget.items[index]),
              child: Row(
                children: [
                  const SizedBox(
                    width: 11,
                  ),
                  Text(
                    widget.items[index].title.toString(),
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500),
                  ),
                  // SizedBox(
                  //   width: 7,
                  // ),
                  if (widget.items[index].countFactory != null)
                    FutureBuilder(
                      future: widget.items[index]
                          .countFactory!(widget.items[index].value),
                      builder: (context, snapshot) {
                        return Padding(
                          padding: const EdgeInsets.all(5),
                          child: SizedBox.square(
                            dimension: 22,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                    shape: BoxShape.circle),
                                child: Center(
                                    child: !snapshot.hasData
                                        ? const CircularProgressIndicator()
                                        : Text(
                                            snapshot.data.toString(),
                                            style: TextStyle(
                                                color: isSelected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSecondary),
                                          ))),
                          ),
                        );
                      },
                    ),

                  if (widget.items[index].countFactory == null)
                    const SizedBox(
                      width: 11,
                    ),
                ],
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
