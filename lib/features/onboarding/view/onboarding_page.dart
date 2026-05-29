import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/language_button.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/common/widgets/secondary_background_graphic.dart';
import 'package:syncora_frontend/common/widgets/version_display.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/onboarding/view/onboarding_popups.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    void guestLogin() async {
      if (user.isLoading) return;
      String? username = await OnboardingPopups.guestPopup(context);

      if (username != null) {
        ref.read(authProvider.notifier).loginAsGuest(username);
      }
    }

    final lightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: OverlayLoader(
        isLoading: user.isLoading,
        body: Stack(
          children: [
            const SecondaryBackgroundGraphic(),

            Padding(
              padding:
                  AppSpacing.paddingHorizontalLg + AppSpacing.paddingVerticalXl,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      LanguageButton(),
                    ],
                  ),
                  const Spacer(
                    flex: 1,
                  ),
                  // LOGO
                  Center(
                    child: Container(
                      alignment: Alignment.center,
                      width: 205 - (MediaQuery.of(context).size.height * 0.01),
                      height: 205 - (MediaQuery.of(context).size.height * 0.01),
                      decoration: BoxDecoration(
                        color: lightMode
                            ? Colors.white
                            : Color(0xFF1A182D).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      child: SizedBox.square(
                        child: SvgPicture.asset(
                          "assets/logos/syncora-logo.svg",
                          height: 115,
                          colorFilter: ColorFilter.mode(
                              lightMode
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary,
                              BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(
                    flex: 2,
                  ),

                  // TITLE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: kIsWeb
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).onboardingPage_Title,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // DESCRIPTION
                  Text(
                    AppLocalizations.of(context).onboardingPage_Description,
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.start,
                    softWrap: true,
                  ),

                  const SizedBox(height: 48),
                  // CREATE ACCOUNT BUTTON
                  AppButton(
                    breadcrumbLabel: () => "Create new account",
                    // highlighted: true,
                    fontSize: 16,
                    // variant: AppButtonVariant.wide,
                    size: AppButtonSize.large,
                    style: AppButtonStyle.filled,
                    intent: AppButtonIntent.primary,
                    onPressed: () => context.pushNamed('sign-up'),
                    child: Text(AppLocalizations.of(context)
                        .onboardingPage_CreateAccount),
                  ),
                  const SizedBox(height: 24),
                  // CONTINUE AS A GUEST
                  AppButton(
                    breadcrumbLabel: () => "Continue as guest",

                    fontSize: 16,
                    size: AppButtonSize.large,
                    style: lightMode
                        ? AppButtonStyle.glow
                        : AppButtonStyle.outlined,
                    intent: AppButtonIntent.primary,
                    // style: Theme.of(context).elevatedButtonTheme.style,
                    onPressed: guestLogin,
                    child: Text(AppLocalizations.of(context)
                        .onboardingPage_ContinueAsGuest),
                  ),
                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () {
                      context.pushNamed('sign-in');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline),
                            "${AppLocalizations.of(context).onboardingPage_AlreadyHaveAccount} "),
                        Text(
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                            AppLocalizations.of(context).signIn)
                      ],
                    ),
                  )
                ],
              ),
            ),

            // APP VERSION
            const VersionDisplay()
          ],
        ),
      ),
    );
  }
}
