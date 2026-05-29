import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';

/// Search bar used to assign users to a task
class TasksSearchBar extends ConsumerStatefulWidget {
  const TasksSearchBar({super.key, required this.onSearch});

  final void Function(String query) onSearch;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TasksSearchBarState();
}

class _TasksSearchBarState extends ConsumerState<TasksSearchBar> {
  SearchController controller = SearchController();
  FocusScopeNode focusScopeNode = FocusScopeNode();
  bool dismissedBar = false;

  @override
  void initState() {
    super.initState();
    // Wait for the frame to load, then remove focus
    // This is to avoid the search bar being focused when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // We get the in memory list of previous search queries for this search bar
    List<String> suggestions = ref.read(searchBarSuggestionsProvider("tasks"));

    void onSearch(String query) {
      dismissedBar = true;
      widget.onSearch(query);
      if (query.isEmpty) return;

      // We add the query to the in memory list of previous search queries
      ref
          .read(searchBarSuggestionsProvider("tasks").notifier)
          .addSuggestion(query);
      // controller.(query);
    }

    return SizedBox(
      height: 57,
      child: FocusScope(
        canRequestFocus: false,
        node: focusScopeNode,
        onFocusChange: (value) {
          if (dismissedBar) {
            focusScopeNode.unfocus();
            dismissedBar = false;
          }
        },
        child: SearchAnchor.bar(
          viewConstraints: const BoxConstraints(maxHeight: 200),
          searchController: controller,
          isFullScreen: false,
          barHintText: AppLocalizations.of(context).signUpPage_Username_Field,
          barLeading: const Icon(Icons.search),
          onSubmitted: (value) {
            if (!controller.isAttached || !controller.isOpen) return;
            controller.closeView(value);
          },
          onClose: () {
            if (!controller.isAttached) return;

            onSearch(controller.text);
          },
          suggestionsBuilder:
              (BuildContext context, SearchController controller) {
            // dismissedBar = false;
            // return
            return List.generate(
              suggestions.length,
              (index) {
                return ListTile(
                  title: Text(suggestions[index]),
                  onTap: () {
                    if (!controller.isAttached || !controller.isOpen) return;

                    controller.closeView(suggestions[index]);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
