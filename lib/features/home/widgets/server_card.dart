import 'package:desk_switch/models/server.dart';
import 'package:flutter/material.dart';

class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.data,
    required this.isPinned,
    required this.isSelected,
    required this.onTap,
    required this.onPinToggle,
  });

  final Server data;
  final bool isPinned;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPinToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.only(
        left: 16,
        right: 8,
      ),
      selectedTileColor: theme.colorScheme.primaryContainer,
      selected: isSelected,
      leading: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 4),
            child: Icon(
              Icons.computer,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: _buildStatusIndicator(theme),
            ),
          ),
        ],
      ),
      title: Text(
        data.name,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        data.host ?? 'Unknown',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          size: 20,
          color: isPinned
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        tooltip: isPinned ? 'Unpin server' : 'Pin server',
        onPressed: onPinToggle,
      ),
      onTap: onTap,
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    const size = 10.0;

    switch (data.status) {
      case ServerStatus.connected:
        // Show blue connected icon
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            size: size - 2,
            color: theme.colorScheme.surfaceContainerLow,
          ),
        );
      case ServerStatus.connecting:
      case ServerStatus.disconnecting:
        // Show loading animation for connecting state
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        );
      case ServerStatus.online:
      case null:
        // Show green dot for online
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        );
      case ServerStatus.offline:
        // Show outline variant dot for offline
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}
