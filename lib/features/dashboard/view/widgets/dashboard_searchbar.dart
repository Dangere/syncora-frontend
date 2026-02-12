import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

class DashboardSearchBar extends ConsumerStatefulWidget {
  const DashboardSearchBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DashboardSearchBarState();
}

class _DashboardSearchBarState extends ConsumerState<DashboardSearchBar> {
  SearchController controller = SearchController();
  FocusScopeNode focusScopeNode = FocusScopeNode();
  bool dismissedBar = false;

  @override
  void initState() {
    super.initState();
    // Wait for the frame to load, then remove focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    Logger().d("DashboardSearchBar build");

    List<String> suggestions = ref.read(searchBarSuggestionsProvider);
    void onSearch(String query) {
      dismissedBar = true;
      ref
          .read(groupsNotifierProvider.notifier)
          .searchGroups(query.isEmpty ? null : query);
      if (query.isEmpty) return;
      ref.read(searchBarSuggestionsProvider.notifier).addSuggestion(query);
      // controller.(query);
    }

    return Padding(
      padding: AppSpacing.paddingHorizontalLg,
      child: SizedBox(
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
            searchController: controller,
            isFullScreen: false,
            // barHintText: ,

            barHintText:
                AppLocalizations.of(context).dashboardPage_SearchGroups,
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
      ),
    );
  }
}
