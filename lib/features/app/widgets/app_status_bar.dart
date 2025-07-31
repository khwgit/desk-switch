import 'package:desk_switch/features/shared/providers/kvm_switch.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppStatusBar extends HookConsumerWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kvmStatus = ref.watch(
      kvmSwitchProvider.select((state) => state.status),
    );
    final theme = Theme.of(context);

    // Determine status
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (kvmStatus) {
      case KvmSwitchStatus.serving:
        statusText = 'Server Running';
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle_fill;
        break;
      case KvmSwitchStatus.booting:
        statusText = 'Starting Server...';
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case KvmSwitchStatus.stopping:
        statusText = 'Stopping Server...';
        statusColor = Colors.red;
        statusIcon = Icons.sync;
        break;
      case KvmSwitchStatus.connected:
        statusText = 'Connected to Server';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case KvmSwitchStatus.connecting:
        statusText = 'Connecting to Server...';
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case KvmSwitchStatus.disconnecting:
        statusText = 'Disconnecting from Server...';
        statusColor = Colors.red;
        statusIcon = Icons.sync;
        break;
      case KvmSwitchStatus.idle:
        statusText = 'Ready';
        statusColor = Colors.grey;
        statusIcon = Icons.pause_circle_filled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Gap(12),
          // Status indicator icon
          Icon(statusIcon, color: statusColor, size: 16),
          const Gap(6),
          // Status text
          Text(
            statusText,
            style: theme.textTheme.bodyMedium?.copyWith(color: statusColor),
          ),
          const Spacer(),
          // Mode indicator
          if (kvmStatus != KvmSwitchStatus.idle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kvmStatus.isServerMode
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kvmStatus.isServerMode
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                kvmStatus.isServerMode ? 'SERVER' : 'CLIENT',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: kvmStatus.isServerMode ? Colors.blue : Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          const Gap(12),
        ],
      ),
    );
  }
}
