import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
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
                  LanguageExpandableCard(
                    currentLocale: currentLocale,
                    onTap: updateLanguage,
                  ),
                  Card(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    )),
                    child: SizedBox(
                      height: 66,
                      width: double.infinity,
                      child: Text(AppLocalizations.of(context).darkMode),
                    ),
                  ),

                  const Spacer(),
                  // LOGOUT BUTTON
                  AppButton(
                      variant: AppButtonVariant.glow,
                      onPressed: logout,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context).logout,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant)),
                          const Icon(
                            Icons.logout,
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
        shadowColor: Colors.transparent,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: ExpansionTile(
          // minTileHeight: 40.0,
          leading: const Icon(Icons.translate_outlined),
          shape: const Border(),
          // backgroundColor: Theme.of(context).colorScheme.surface,
          // collapsedBackgroundColor: Theme.of(context).colorScheme.surface,
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
                    variant: AppButtonVariant.dropdown,
                    onPressed: () => onTap(const Locale("en")),
                    fontSize: 16,
                    child: const Text("English"),

                    // disabled: true,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    highlighted: currentLocale.languageCode == "ar",
                    variant: AppButtonVariant.dropdown,
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
