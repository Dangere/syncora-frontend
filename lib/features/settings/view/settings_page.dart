import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  void logout() {
    ref.read(authNotifierProvider.notifier).logout();
  }

  void updateLanguage(Locale locale) {
    ref.read(localeNotifierProvider.notifier).setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerErrorListener(ref, context);

    Locale currentLocale = ref.watch(localeNotifierProvider);
    // bool isDarkMode = ref.watch(themeModeProvider);

    bool isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).settingsPage_Title),
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: AppSpacing.paddingHorizontalLg +
                  AppSpacing.paddingVerticalXl +
                  const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  // LANGUAGE
                  LanguageExpandableCard(
                    currentLocale: currentLocale,
                    onTap: updateLanguage,
                  ),
                  const SizedBox(height: 16),
                  // TOGGLE DARK MODE
                  AppButton(
                    fontSize: 16,
                    size: AppButtonSize.huge,
                    style: AppButtonStyle.filled,
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.dark_mode_sharp, size: 24),

                        // Icon(Icons.dark_mode_sharp, size: 24),
                        // Icon(Icons.dark_mode_sharp, size: 24),

                        const SizedBox(width: 17),
                        Text(
                          AppLocalizations.of(context).darkMode,
                        ),

                        const Spacer(),
                        FlutterSwitch(
                          // padding: const EdgeInsets.all(0),
                          toggleColor:
                              Theme.of(context).colorScheme.surfaceContainer,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveColor: Theme.of(context).colorScheme.scrim,
                          toggleSize: 16,
                          height: 24,
                          width: 44,
                          value: isDarkMode,
                          onToggle: (value) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemDark(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CHANGE PASSWORD
                  AppButton(
                    fontSize: 16,
                    size: AppButtonSize.huge,
                    style: AppButtonStyle.filled,
                    onPressed: () {},
                    child: Row(
                      children: [
                        const Icon(Icons.lock, size: 24),

                        // Icon(Icons.dark_mode_sharp, size: 24),
                        // Icon(Icons.dark_mode_sharp, size: 24),

                        const SizedBox(width: 17),
                        Text(
                          AppLocalizations.of(context)
                              .settingsPage_ChangeMyPassword,
                        ),

                        const Spacer(),
                        Transform.rotate(
                            angle: 3.14 * (3 / 2),
                            child: const Icon(Icons.expand_more, size: 24)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // LOGOUT BUTTON
                  AppButton(
                      size: AppButtonSize.huge,
                      style: AppButtonStyle.filled,
                      intent: AppButtonIntent.destructive,
                      onPressed: logout,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context).logout),
                          const Icon(
                            Icons.logout,
                            size: 26,
                          ),
                        ],
                      )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class LanguageExpandableCard extends StatelessWidget {
  const LanguageExpandableCard({
    super.key,
    required this.currentLocale,
    required this.onTap,
  });

  final Locale currentLocale;
  final Func<Locale, void> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [AppShadow.shadow0(context)],
      ),
      child: Card(
        margin: const EdgeInsets.all(0),
        shadowColor: Colors.transparent,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: ExpansionTile(
          // childrenPadding: EdgeInsets.all(0),
          minTileHeight: 66,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.translate_outlined,
            size: 24,
          ),
          shape: const Border(),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          collapsedBackgroundColor:
              Theme.of(context).colorScheme.surfaceContainer,
          title: Text(AppLocalizations.of(context).language,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontWeight: FontWeight.w700)),
          children: [
            Divider(
              height: 0.8,
              color: Theme.of(context).colorScheme.scrim.withOpacity(0.4),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  AppButton(
                    highlighted: currentLocale.languageCode == "en",
                    size: AppButtonSize.medium,
                    style: AppButtonStyle.dropdown,
                    onPressed: () => onTap(const Locale("en")),
                    fontSize: 16,
                    child: const Text("English"),

                    // disabled: true,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    highlighted: currentLocale.languageCode == "ar",
                    size: AppButtonSize.medium,
                    style: AppButtonStyle.dropdown,
                    onPressed: () => onTap(const Locale("ar")),
                    fontSize: 16,
                    child: const Text("عربي"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
