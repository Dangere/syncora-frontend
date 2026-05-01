import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/date_utilities.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/groups/view/popups/group_popups.dart';

// TODO: Seperate the members update trigger from the groups tasks updates
class GroupInfoPage extends ConsumerStatefulWidget {
  const GroupInfoPage({super.key, required this.groupId});
  final int groupId;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends ConsumerState<GroupInfoPage> {
  late bool isOwner = false;
  bool isEditingMembers = false;

  void onGroupDescriptionEdit(String? defaultDescription) async {
    String? newDescription = await GroupPopups.groupDescriptionEditPopup(
        context, defaultDescription ?? "");

    if (newDescription == null) {
      return;
    }

    await ref.read(groupProvider(widget.groupId).notifier).updateGroupDetails(
        groupId: widget.groupId, description: newDescription);
  }

  void onMembersEdit() async {
    if (displayedMembers.length <= 1) {
      SnackBarAlerts.showAlertSnackBar(
          AppLocalizations.of(context).groupInfoPopup_Alert_NoMembers, context);
      isEditingMembers = false;
      return;
    }
    ;
    setState(() {
      isEditingMembers = !isEditingMembers;
    });
  }

  void onDeleteMember(String username) {
    ref
        .read(groupProvider(widget.groupId).notifier)
        .removeUserAccessToGroup(username);
  }

  // Returns the members with the group owner being the first element
  Future<List<User>> getMembers() =>
      ref.read(groupProvider(widget.groupId).notifier).getGroupMembers(true);

  void onMemberClick(int id) =>
      context.pushNamed("profile-view", pathParameters: {"id": id.toString()});

  List<User> displayedMembers = List.empty(growable: true);

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerNotificationListener(ref, context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
            "${AppLocalizations.of(context).groupInfoPage_Title}${kDebugMode ? " [${widget.groupId.toString()}]" : ""}"),
      ),
      body: ref.watch(groupProvider(widget.groupId)).when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            data: (data) {
              if (data == null) {
                return Center(
                    child: Text(
                        AppLocalizations.of(context).appError_GroupNotFound));
              }

              isOwner = ref
                  .read(groupProvider(widget.groupId).notifier)
                  .isGroupOwner();

              return Padding(
                padding: AppSpacing.paddingHorizontalLg +
                    AppSpacing.paddingVerticalMd +
                    EdgeInsets.only(bottom: 60),
                child: Column(
                  children: [
                    // GROUP INFO
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          AppShadow.shadow0(context),
                        ],
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 24.0, right: 24.0, top: 20.0, bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context).general,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                ),
                              ],
                            ),
                            AppSpacing.verticalSpaceLg,
                            RichText(
                                text: TextSpan(children: [
                              TextSpan(
                                  text:
                                      '${AppLocalizations.of(context).name}: ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontWeight: FontWeight.w600)),
                              TextSpan(
                                  text: data.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                            ])),
                            const SizedBox(
                              height: 12,
                            ),
                            RichText(
                                text: TextSpan(children: [
                              TextSpan(
                                  text:
                                      '${AppLocalizations.of(context).description}: ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontWeight: FontWeight.w600)),
                              TextSpan(
                                  text: data.description ??
                                      AppLocalizations.of(context)
                                          .groupInfoPage_NoDescription,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                              if (isOwner)
                                TextSpan(
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => onGroupDescriptionEdit(
                                          data.description),
                                    text:
                                        " ${AppLocalizations.of(context).edit}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                            fontWeight: FontWeight.w400,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary)),
                            ])),
                            const SizedBox(
                              height: 12,
                            ),
                            RichText(
                                text: TextSpan(children: [
                              TextSpan(
                                  text:
                                      '${AppLocalizations.of(context).groupInfoPage_CreatedIn}: ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontWeight: FontWeight.w600)),
                              TextSpan(
                                  text: DateUtilities.getFormattedDate(
                                      data.creationDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                            ])),
                            // Text(
                            //   "Name: ${data.title}",
                            //   style: Theme.of(context)
                            //       .textTheme
                            //       .titleSmall!
                            //       .copyWith(
                            //           fontWeight: FontWeight.w700,
                            //           color: Theme.of(context)
                            //               .colorScheme
                            //               .onSurfaceVariant),
                            // ),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.verticalSpaceLg,
                    // MEMBERS
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            AppShadow.shadow0(context),
                          ],
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadius0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 24.0, right: 24.0, top: 20.0, bottom: 24.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).members,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                  ),
                                  if (isOwner)
                                    RichText(
                                      text: TextSpan(
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => onMembersEdit(),
                                          text:
                                              AppLocalizations.of(context).edit,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                  fontWeight: FontWeight.w400,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary)),
                                    )
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Expanded(
                                child: FutureBuilder(
                                    future: getMembers(),
                                    builder: (context, asyncSnapshot) {
                                      if (asyncSnapshot.connectionState ==
                                              ConnectionState.waiting &&
                                          displayedMembers.isEmpty) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }

                                      displayedMembers =
                                          asyncSnapshot.data ?? [];

                                      return ListView.separated(
                                        itemCount: displayedMembers.length,
                                        itemBuilder: (context, index) {
                                          return Row(
                                            children: [
                                              ProfilePicture(
                                                onClick: () => onMemberClick(
                                                    displayedMembers[index].id),
                                                userId:
                                                    displayedMembers[index].id,
                                                radius: 22,
                                              ),
                                              const SizedBox(
                                                width: 16,
                                              ),
                                              Text(
                                                displayedMembers[index]
                                                    .username,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge!
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .outline),
                                              ),
                                              Spacer(),
                                              // If its the first element (the owner)
                                              if (index == 0)
                                                Text(
                                                  AppLocalizations.of(context)
                                                      .owner,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary),
                                                ),
                                              if (index != 0 &&
                                                  isEditingMembers)
                                                IconButton(
                                                    onPressed: () =>
                                                        onDeleteMember(
                                                            displayedMembers[
                                                                    index]
                                                                .username),
                                                    icon: Icon(Icons.delete))
                                            ],
                                          );
                                        },
                                        separatorBuilder: (context, index) {
                                          return const SizedBox(
                                            height: 16,
                                          );
                                        },
                                      );
                                    }),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            error: (error, stackTrace) {
              return Center(
                child: Text(
                  ref.read(localizeAppErrorsProvider).localizeErrorCode(
                      AppError.fromException(error, stackTrace).errorCode,
                      context),
                ),
              );
            },
            loading: () {
              return const Center(child: CircularProgressIndicator());
            },
          ),
    );
  }
}
