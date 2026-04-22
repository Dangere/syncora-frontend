import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/google_auth_type_enum.dart';
import 'package:syncora_frontend/features/authentication/models/google_user_info.dart';

// Mobile implementation of the google auth button
class GoogleAuthButton extends ConsumerWidget {
  const GoogleAuthButton({super.key, required this.type});
  final GoogleAuthType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(googleSignInProvider).onCurrentUserChanged.listen((account) async {
      if (context.mounted) {
        if (account == null) return;

        var auth = await account.authentication;

        if (context.mounted) {
          switch (type) {
            case GoogleAuthType.signIn:
              ref.read(authProvider.notifier).loginUsingGoogle(auth.idToken!);

            case GoogleAuthType.signUp:
              List<String> fullName = account.displayName?.split(" ") ?? [];
              var userInfo = GoogleUserInfo(
                  token: auth.idToken!,
                  email: account.email,
                  firstName: fullName.isNotEmpty ? fullName[0] : "",
                  lastName: fullName.length > 1 ? fullName[1] : "");

              context.pushNamed("google-sign-up", extra: userInfo);
          }
        }
      }
    });

    return AppButton(
        size: AppButtonSize.large,
        style: AppButtonStyle.glow,
        onPressed: () async {
          if (ref.read(authProvider).isLoading) return;
          await ref.read(googleSignInProvider).signOut();
          ref.read(googleSignInProvider).signIn();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/logos/google-icon.svg",
              semanticsLabel: 'Google Logo',
              height: 20,
            ),
            const SizedBox(width: 10),
            Text(
                type == GoogleAuthType.signIn
                    ? AppLocalizations.of(context).signInPage_GoogleSignIn
                    : AppLocalizations.of(context).signUpPage_GoogleSignUp,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.outlineVariant)),
          ],
        ));
  }
}
