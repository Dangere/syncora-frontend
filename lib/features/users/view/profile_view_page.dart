import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';
import 'package:syncora_frontend/features/users/view/profile_popups.dart';

class ProfileViewPage extends ConsumerStatefulWidget {
  const ProfileViewPage({super.key, required this.userId});

  final int userId;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProfileViewPageState();
}

class _ProfileViewPageState extends ConsumerState<ProfileViewPage> {
  final _formKey = GlobalKey<FormState>();
  final FocusScopeNode focusScopeNode = FocusScopeNode();

  bool editMode = false;
  User? user;

  late bool isAccountOwner;

  // Result<User?> user =  ref.watch(usersServiceProvider).getUser(widget.userId).then(onValue);

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  Future changeProfilePicture() async {
    if (ref.read(userProvider).isLoading) return;

    ImageSource? source = await ProfilePopups.chooseImageSource(context);

    if (source == null) return;

    String? imageUrl =
        await ref.read(userProvider.notifier).changeProfilePicture((arg) async {
      if (mounted) {
        Uint8List? croppedImageBytes =
            await context.push<Uint8List>('/crop-image', extra: arg);

        return croppedImageBytes;
      }
      return null;
    }, source);

    if (mounted && imageUrl != null) {
      SnackBarAlerts.showSuccessSnackBar(
          AppLocalizations.of(context).profileViewPage_ProfileChange, context);
    }
  }

  void setEditMode(bool enabled, void Function(void Function()) setState) {
    focusScopeNode.unfocus();
    _formKey.currentState?.reset();
    if (!isAccountOwner) return;
    setState(() {
      editMode = enabled;
    });
  }

  void resetFields() {
    ref.read(loggerProvider).i("Resetting fields");
    firstNameController.text = user == null ? "" : user!.firstName;
    lastNameController.text = user == null ? "" : user!.lastName;
    usernameController.text = user == null ? "" : user!.username;
    emailController.text = user == null ? "" : user!.email;
  }

  void onEditButton(void Function(void Function()) setState) {
    if (editMode) resetFields();
    setEditMode(!editMode, setState);
  }

  void onSaveButton(void Function(void Function()) setState) async {
    if (!isAccountOwner || user == null) return;
    if (_formKey.currentState!.validate()) {
      ref.read(loggerProvider).i("Profile page: Updating user info!");

      await ref.read(userProvider.notifier).updateUserProfile(
            firstName: user!.firstName == firstNameController.text
                ? null
                : firstNameController.text,
            lastName: user!.lastName == lastNameController.text
                ? null
                : lastNameController.text,
            username: user!.username == usernameController.text
                ? null
                : usernameController.text,
          );

      //TODO: Having this line of code to unfocus from the inputfield literally breaks things
      // It makes every interaction with the input feild trigger a rebuild??
      // if (mounted) FocusScope.of(context).unfocus();
      setEditMode(false, setState);
    }
  }

  @override
  void initState() {
    isAccountOwner = ref.read(authProvider).value!.userId! == widget.userId;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerNotificationListener(ref, context);

    AsyncValue<User?> userAsync = ref.watch(userLocalProvider(widget.userId));
    // bool isLoading = READ.read(userProvider).isLoading;

    return userAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (data) {
        if (data == null) {
          ref.read(loggerProvider).i("Building profile view page");

          return const Center(
            // TODO: Localize strings in this widget
            child: Text("User doesn't exist"),
          );
        }

        ref
            .read(loggerProvider)
            .i("Building profile view page and updating displayed data");

        // Updating the user data (if its updated from the backend)
        user = data;
        // Resetting the fields every time the user data is updated
        resetFields();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            centerTitle: true,
            title: Text(isAccountOwner
                ? AppLocalizations.of(context).profileViewPage_TitleMyProfile
                : AppLocalizations.of(context).profileViewPage_TitleProfile),
          ),
          body: OverlayLoader(
            isLoading: ref.watch(userProvider).isLoading,
            body: SingleChildScrollView(
              child: Padding(
                padding: AppSpacing.paddingHorizontalLg +
                    AppSpacing.paddingVerticalXl +
                    const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    AppSpacing.verticalSpaceMd,
                    // PROFILE PICTURE
                    Stack(
                      children: [
                        ProfilePicture(userId: widget.userId, radius: 60),
                        if (isAccountOwner)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  shape: BoxShape.circle),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                                child: CircleAvatar(
                                  radius: 14,
                                  child: IconButton(
                                    onPressed: changeProfilePicture,
                                    padding: const EdgeInsets.all(0),
                                    icon: Icon(
                                      size: 18,
                                      Icons.edit,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 42,
                    ),
                    // INFO
                    infoCard(data)
                  ],
                ),
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return Center(
          child: Text(
            ref.read(localizeAppErrorsProvider).localizeErrorCode(
                AppError.fromException(error, stackTrace).errorCode, context),
          ),
        );
      },
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget infoCard(User user) {
    return StatefulBuilder(builder: (context, setState) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [AppShadow.shadow0(context)],
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius0),
        ),
        child: AnimatedSize(
          alignment: Alignment.topCenter,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutBack,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              const SizedBox(
                height: 15,
              ),
              // TITLE AND EDIT BUTTON
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TITLE
                  Text(
                    isAccountOwner
                        ? AppLocalizations.of(context)
                            .profileViewPage_MyInfoTitle
                        : AppLocalizations.of(context)
                            .profileViewPage_InfoTitle,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold),
                  ),
                  // EDIT BUTTON
                  SizedBox.square(
                    dimension: 40,
                    child: !isAccountOwner
                        ? null
                        : CircleAvatar(
                            radius: 20,
                            child: IconButton(
                              onPressed: () => onEditButton(setState),
                              padding: const EdgeInsets.all(0),
                              icon: Icon(
                                size: 22,
                                Icons.edit,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(
                height: 26,
              ),
              // FORM
              AbsorbPointer(
                absorbing: !editMode,
                child: FocusScope(
                  node: focusScopeNode,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // FIRST AND LAST NAME
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // FIRST NAME
                            Expanded(
                              child: InputField(
                                keyboardType: TextInputType.name,
                                hintText: AppLocalizations.of(context)
                                    .signUpPage_Name_Field,
                                labelText: AppLocalizations.of(context)
                                    .signUpPage_FirstName,
                                controller: firstNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)
                                        .validation_Name_Empty;
                                  }

                                  if (Validators.validateName(value.trim()) ==
                                      false) {
                                    return AppLocalizations.of(context)
                                        .validation_Name_Invalid;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            AppSpacing.horizontalSpaceMd,

                            // LAST NAME
                            Expanded(
                              child: InputField(
                                keyboardType: TextInputType.name,
                                hintText: AppLocalizations.of(context)
                                    .signUpPage_Name_Field,
                                labelText: AppLocalizations.of(context)
                                    .signUpPage_LastName,
                                controller: lastNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)
                                        .validation_Name_Empty;
                                  }

                                  if (Validators.validateName(value.trim()) ==
                                      false) {
                                    return AppLocalizations.of(context)
                                        .validation_Name_Invalid;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // USERNAME
                        InputField(
                          suffixIcon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.name,
                          labelText:
                              AppLocalizations.of(context).signUpPage_Username,
                          hintText: AppLocalizations.of(context)
                              .signUpPage_Username_Field,
                          controller: usernameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)
                                  .validation_Username_Empty;
                            }

                            if (Validators.validateUsername(value.trim()) ==
                                false) {
                              return AppLocalizations.of(context)
                                  .validation_Username_Invalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // EMAIL
                        AbsorbPointer(
                          absorbing: true,
                          child: InputField(
                            suffixIcon: Icons.email_outlined,
                            labelText: AppLocalizations.of(context).email,
                            hintText: AppLocalizations.of(context).email_Field,
                            keyboardType: TextInputType.emailAddress,
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)
                                    .validation_Email_Empty;
                              }

                              if (Validators.validateEmail(value.trim()) ==
                                  false) {
                                return AppLocalizations.of(context)
                                    .validation_Email_Invalid;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // SAVE BUTTON
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: editMode
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        child: AppButton(
                            size: AppButtonSize.large,
                            style: AppButtonStyle.filled,
                            intent: AppButtonIntent.primary,
                            onPressed: () => onSaveButton(setState),
                            child: Text(AppLocalizations.of(context).save)),
                      )
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      );
    });
  }
}
