import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class VerifyEmailPanel extends StatelessWidget {
  const VerifyEmailPanel(
      {super.key, required this.authState, required this.ref});
  final AuthState authState;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              color: Colors.yellow[100]),
          child: Column(
            children: [
              RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      text:
                          'Please verify your email ${authState.user!.email}, or ',
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        TextSpan(
                            text: 'Click here',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                Result result = await ref
                                    .read(authNotifierProvider.notifier)
                                    .sendVerificationEmail();
                                if (result.isSuccess) {
                                  ref.read(loggerProvider).i("Email sent");
                                  SnackBarAlerts.showSuccessSnackBar(
                                      "Verification email sent", context);
                                }
                              })
                      ]))
            ],
          )),
    );
  }
}
