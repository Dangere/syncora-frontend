import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_web/web_only.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/google_auth_type_enum.dart';
import 'package:syncora_frontend/features/authentication/models/google_user_info.dart'; // ← this is where renderButton lives

// Web implementation of the google auth button
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

    print(ref.read(localeProvider).languageCode);

    return SizedBox(
      height: 56.0,
      width: double.infinity,
      child: renderButton(
        configuration: GSIButtonConfiguration(
          type: GSIButtonType.standard,
          theme: GSIButtonTheme.outline,
          shape: GSIButtonShape.pill,
          locale: ref.read(localeProvider).languageCode,
          text: type == GoogleAuthType.signIn
              ? GSIButtonText.signin
              : GSIButtonText.signupWith,
          minimumWidth: 240,
        ),
      ),
    );
  }
}
