import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/view/popups/auth_popups.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showPassword = false;

  @override
  void dispose() {
    super.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);

    SnackBarAlerts.registerErrorListener(ref, context);

    void register() {
      if (!_formKey.currentState!.validate() || user.isLoading) return;
      ref.read(authNotifierProvider.notifier).registerWithEmailAndPassword(
          emailController.text.trim(),
          usernameController.text.trim(),
          passwordController.text.trim());
    }

    void googleRegister() {
      ref.read(authNotifierProvider.notifier).registerUsingGoogle(
            (p0) => AuthPopups.displayRegisterInfoGetter(context, ref),
          );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Center(child: Text(AppLocalizations.of(context).registerPageTitle)),
        elevation: 0,
      ),
      body: OverlayLoader(
        isLoading: user.isLoading,
        overlay: const CircularProgressIndicator(),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Text("Syncora",
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge!
                      .copyWith(fontSize: 60)
                      .copyWith(color: Theme.of(context).colorScheme.primary)
                      .copyWith(fontWeight: FontWeight.bold)),
              // Forms and register button
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    labelText: 'First Name'),
                                keyboardType: TextInputType.emailAddress,
                                controller: usernameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'First name cannot be empty';
                                  }

                                  if (Validators.validateUsername(
                                          value.trim()) ==
                                      false) {
                                    return 'Invalid first name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            AppSpacing.verticalSpaceLg,
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    labelText: 'Last Name'),
                                keyboardType: TextInputType.emailAddress,
                                controller: usernameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Last name cannot be empty';
                                  }

                                  if (Validators.validateUsername(
                                          value.trim()) ==
                                      false) {
                                    return 'Invalid last name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ]),
                      // Username field
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Username'),
                        keyboardType: TextInputType.emailAddress,
                        controller: usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username cannot be empty';
                          }

                          if (Validators.validateUsername(value.trim()) ==
                              false) {
                            return 'Invalid username';
                          }
                          return null;
                        },
                      ),

                      // Email field
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }

                          if (Validators.validateEmail(value.trim()) == false) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      // Passwords field
                      StatefulBuilder(builder: (context, setState) {
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Password'),
                                    obscureText: !showPassword,
                                    controller: passwordController,
                                    keyboardType: TextInputType.visiblePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password cannot be empty';
                                      }

                                      if (Validators.validatePassword(
                                              value.trim()) ==
                                          false) {
                                        return 'Password must be between 6 and 16 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15.0),
                                  child: IconButton(
                                      alignment: Alignment.center,
                                      onPressed: () {
                                        setState(() {
                                          showPassword = !showPassword;
                                        });
                                      },
                                      icon: Icon(!showPassword
                                          ? Icons.remove_red_eye_outlined
                                          : Icons.remove_red_eye)),
                                )
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Confirm Password'),
                                    obscureText: !showPassword,
                                    controller: confirmPasswordController,
                                    keyboardType: TextInputType.visiblePassword,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Password cannot be empty';
                                      }

                                      if (value.trim() !=
                                          passwordController.text.trim()) {
                                        return "Password does not match";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15.0),
                                  child: IconButton(
                                      alignment: Alignment.center,
                                      onPressed: () {
                                        setState(() {
                                          showPassword = !showPassword;
                                        });
                                      },
                                      icon: Icon(!showPassword
                                          ? Icons.remove_red_eye_outlined
                                          : Icons.remove_red_eye)),
                                )
                              ],
                            ),
                          ],
                        );
                      }),
                      AppSpacing.horizontalSpaceLg,
                      ElevatedButton(
                          onPressed: register,
                          child: Text(
                              AppLocalizations.of(context).registerPageTitle)),
                    ],
                  ),
                ),
              ),
              AppSpacing.horizontalSpaceLg,
              ElevatedButton(
                  onPressed: googleRegister,
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.grey.shade200),
                      padding:
                          MaterialStateProperty.all(const EdgeInsets.all(10))),
                  child: Container(
                    // color: Colors.amber,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: SvgPicture.asset(
                              "assets/logos/google-icon.svg",
                              semanticsLabel: 'Google Logo'),
                        ),
                        SizedBox(width: 9),
                        const Text("Sign in with Google",
                            style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  )),
              AppSpacing.horizontalSpaceLg,

              // Footer
              TextButton(
                  onPressed: () {
                    // TODO: Put register screen nav here
                    context.replace('/login');
                  },
                  child: SizedBox(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            style: Theme.of(context).textTheme.bodyMedium,
                            "Already a user? "),
                        Text(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                            AppLocalizations.of(context).loginPageTitle),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
