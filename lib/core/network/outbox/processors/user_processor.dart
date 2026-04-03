import 'package:syncora_frontend/core/network/outbox/exception/outbox_exception.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/repositories/remote_users_repository.dart';

class UserProcessor extends OutboxProcessor {
  final LocalUsersRepository _localTasksRepository;
  final RemoteUsersRepository _remoteTasksRepository;

  UserProcessor(super.idMapper, super.logger, this._localTasksRepository,
      this._remoteTasksRepository);

  @override
  Future<int> processToBackend(OutboxEntry entry) async {
    switch (entry.actionType) {
      case OutboxActionType.update:
        UpdateUserPreferencesPayload payload =
            entry.payload!.asUpdateUserPreferencesPayLoad!;
        await _remoteTasksRepository.updateUserPreferences(
            darkMode: payload.darkMode, languageCode: payload.languageCode);

        break;

      default:
        throw OutboxException("Unsupported action type: ${entry.toTable()}");
    }

    return entry.entityId;
  }

  @override
  Future<int> revertLocalChange(OutboxEntry entry) async {
    switch (entry.actionType) {
      case OutboxActionType.update:
        // TODO: Handle this case.
        break;

      default:
        throw OutboxException("Unsupported action type: ${entry.toTable()}");
    }
    return entry.entityId;
  }
}
