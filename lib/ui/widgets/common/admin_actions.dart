import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Whether the signed-in account is an owner or admin; actions on the home
/// server are offered only to them, like in the web interface. The server
/// checks again.
Future<bool> isAdmin(BuildContext context) async =>
    switch (await context.read<ServerRepository>().status()) {
      Ok(:final value) => value.role == 'owner' || value.role == 'admin',
      Error() => false,
    };

/// Asks before an action that changes the home server.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.parcelsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// Runs [send] against the current server and says how it went.
Future<void> runAction(
  BuildContext context,
  Future<Result<void>> Function(ServerAddress server) send, {
  required String done,
}) async {
  final server = context.read<ServerRepository>().current;
  if (server == null) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  final result = await send(server);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(switch (result) {
        Ok() => done,
        Error(:final error) => l10n.errorMessage(error),
      }),
    ),
  );
}

/// One choice of an action sheet.
typedef SheetAction = ({IconData icon, String label, VoidCallback onTap});

/// Shows [actions] in a bottom sheet; a single action runs at once, none
/// does nothing.
Future<void> showActions(
  BuildContext context,
  List<SheetAction> actions,
) async {
  if (actions.isEmpty) return;
  if (actions.length == 1) return actions.single.onTap();
  final chosen = await showModalBottomSheet<VoidCallback>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in actions)
            ListTile(
              leading: Icon(a.icon),
              title: Text(a.label),
              onTap: () => Navigator.pop(context, a.onTap),
            ),
        ],
      ),
    ),
  );
  chosen?.call();
}
