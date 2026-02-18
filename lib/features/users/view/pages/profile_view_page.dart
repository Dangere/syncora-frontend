import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class ProfileViewPage extends ConsumerStatefulWidget {
  const ProfileViewPage({super.key, required this.userId});

  final int userId;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProfileViewPageState();
}

class _ProfileViewPageState extends ConsumerState<ProfileViewPage> {
  final _formKey = GlobalKey<FormState>();

  bool editMode = false;

  User? user;
  late bool isCurrentUser;

  // Result<User?> user =  ref.watch(usersServiceProvider).getUser(widget.userId).then(onValue);

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  Future _changeProfilePicture() async {
    if (ref.watch(profilePageNotifierProvider).isLoading) return;

    String? imageUrl = await ref
        .read(profilePageNotifierProvider.notifier)
        .changeProfilePicture(
      (arg) async {
        if (mounted) {
          Uint8List? croppedImageBytes =
              await context.push<Uint8List>('/crop-image', extra: arg);

          return croppedImageBytes;
        }
        return null;
      },
    );

    if (mounted && imageUrl != null) {
      SnackBarAlerts.showSuccessSnackBar(
          AppLocalizations.of(context).profileViewPage_ProfileChange, context);
    }
  }

  void _setEditMode(bool enabled) {
    if (!isCurrentUser) return;
    setState(() {
      editMode = enabled;
      if (!editMode && user != null) {
        _populateFields(user!);
      }
    });
  }

  void _populateFields(User user) {
    user = user;
    firstNameController.text = user.firstName;
    lastNameController.text = user.lastName;
    usernameController.text = user.username;
    emailController.text = user.email;
  }

  void _onSnapshot(AsyncSnapshot<User?> snapshot) {
    if (snapshot.hasError) {
      SnackBarAlerts.showErrorSnackBar(snapshot.error.toString(), context);
    }

    if (snapshot.data != null) {
      _populateFields(snapshot.data!);
    }
  }

  void _saveChanges() async {
    if (!isCurrentUser) return;
    if (_formKey.currentState!.validate()) {
      // await ref.read(profilePageNotifierProvider.notifier).updateProfile(
      //     firstName: firstNameController.text,
      //     lastName: lastNameController.text,
      //     username: usernameController.text,
      //     email: emailController.text);
    }

    FocusScope.of(context).unfocus();
    _setEditMode(false);
  }

  @override
  void initState() {
    isCurrentUser =
        ref.read(authNotifierProvider).value!.user!.id == widget.userId;
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
    SnackBarAlerts.registerErrorListener(ref, context);

    bool isLoading = ref.watch(profilePageNotifierProvider).isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(isCurrentUser
            ? AppLocalizations.of(context).profileViewPage_TitleMyProfile
            : AppLocalizations.of(context).profileViewPage_TitleProfile),
      ),
      body: Padding(
        padding: AppSpacing.paddingHorizontalLg +
            AppSpacing.paddingVerticalXl +
            const EdgeInsets.only(top: 80),
        child: OverlayLoader(
          isLoading: isLoading,
          body: Column(
            children: [
              AppSpacing.verticalSpaceMd,
              // PROFILE PICTURE
              Stack(
                children: [
                  ProfilePicture(userId: widget.userId, radius: 60),
                  if (isCurrentUser)
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
                              onPressed: _changeProfilePicture,
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
              Container(
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
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),

                          // TITLE AND EDIT BUTTON
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isCurrentUser
                                    ? AppLocalizations.of(context)
                                        .profileViewPage_MyInfoTitle
                                    : AppLocalizations.of(context)
                                        .profileViewPage_InfoTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontWeight: FontWeight.bold),
                              ),
                              SizedBox.square(
                                dimension: 40,
                                child: editMode || !isCurrentUser
                                    ? null
                                    : CircleAvatar(
                                        radius: 20,
                                        child: IconButton(
                                          onPressed: () => _setEditMode(true),
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

                          FutureBuilder(
                              future:
                                  ref.watch(userProvider(widget.userId).future),
                              builder: (context, asyncSnapshot) {
                                _onSnapshot(asyncSnapshot);

                                return AbsorbPointer(
                                  absorbing: !editMode,
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // FIRST NAME
                                            Expanded(
                                              child: InputField(
                                                keyboardType:
                                                    TextInputType.name,
                                                hintText:
                                                    AppLocalizations.of(context)
                                                        .signUpPage_Name_Field,
                                                labelText:
                                                    AppLocalizations.of(context)
                                                        .signUpPage_FirstName,
                                                controller: firstNameController,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'First name cannot be empty';
                                                  }

                                                  if (Validators
                                                          .validateUsername(
                                                              value.trim()) ==
                                                      false) {
                                                    return 'Invalid first name';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            AppSpacing.horizontalSpaceMd,

                                            // LAST NAME
                                            Expanded(
                                              child: InputField(
                                                keyboardType:
                                                    TextInputType.name,
                                                hintText:
                                                    AppLocalizations.of(context)
                                                        .signUpPage_Name_Field,
                                                labelText:
                                                    AppLocalizations.of(context)
                                                        .signUpPage_LastName,
                                                controller: lastNameController,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Last name cannot be empty';
                                                  }

                                                  if (Validators
                                                          .validateUsername(
                                                              value.trim()) ==
                                                      false) {
                                                    return 'Invalid last name';
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
                                          suffixIcon:
                                              Icons.person_outline_rounded,
                                          keyboardType: TextInputType.name,
                                          labelText:
                                              AppLocalizations.of(context)
                                                  .signUpPage_Username,
                                          hintText: AppLocalizations.of(context)
                                              .signUpPage_Username_Field,
                                          controller: usernameController,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Username cannot be empty';
                                            }

                                            if (Validators.validateUsername(
                                                    value.trim()) ==
                                                false) {
                                              return 'Invalid username';
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
                                            labelText:
                                                AppLocalizations.of(context)
                                                    .email,
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .email_Field,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            controller: emailController,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Email cannot be empty';
                                              }

                                              if (Validators.validateEmail(
                                                      value.trim()) ==
                                                  false) {
                                                return 'Invalid email';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          const SizedBox(height: 30),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: editMode
                                ? Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 30.0),
                                    child: AppButton(
                                        size: AppButtonSize.large,
                                        style: AppButtonStyle.filled,
                                        intent: AppButtonIntent.primary,
                                        onPressed: _saveChanges,
                                        child: Text(
                                            AppLocalizations.of(context).save)),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ]),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
