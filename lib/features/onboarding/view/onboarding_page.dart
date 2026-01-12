import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/language_button.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
                width: double.infinity,
                // height: 371,
                // fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                fit: BoxFit.fitWidth,
                "assets/images/background.svg"),
          ),
          Padding(
            padding:
                AppSpacing.paddingHorizontalLg + AppSpacing.paddingVerticalXl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Row(
                  children: [
                    LanguageButton(),
                  ],
                ),
                const SizedBox(height: 30),
                // LOGO
                Container(
                  width: 205,
                  height: 205,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                  ),
                  child: Icon(
                    Icons.person_3,
                    size: 150,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),

                Expanded(child: Container()),
                // TITLE
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).onboardingPage_Title,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
                // DESCRIPTION
                Text(
                  AppLocalizations.of(context).onboardingPage_Description,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.start,
                  softWrap: true,
                ),

                const SizedBox(height: 24),
                // CREATE ACCOUNT BUTTON
                AppButton(
                  variant: AppButtonVariant.primary,
                  onPressed: () => context.push('/sign-up'),
                  child: Text(AppLocalizations.of(context)
                      .onboardingPage_CreateAccount),
                ),
                const SizedBox(height: 12),
                // CONTINUE AS A GUEST
                AppButton(
                  variant: AppButtonVariant.glow,
                  // style: Theme.of(context).elevatedButtonTheme.style,
                  onPressed: () {},
                  child: Text(AppLocalizations.of(context)
                      .onboardingPage_ContinueAsGuest),
                ),
                const SizedBox(height: 35),

                TextButton(
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          style: Theme.of(context).textTheme.bodyLarge,
                          "${AppLocalizations.of(context).onboardingPage_AlreadyHaveAccount} "),
                      Text(
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary),
                          AppLocalizations.of(context).signIn)
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
