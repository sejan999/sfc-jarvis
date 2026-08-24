import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';

/// Result of executing a device action.
class DeviceActionResult {
  const DeviceActionResult({required this.success, required this.spokenReply});

  final bool success;
  final String spokenReply;
}

/// Executes hands-free phone automation: app launching, calls, SMS,
/// flashlight toggling and system settings intents.
class DeviceActionService {
  DeviceActionService();

  static const MethodChannel _channel =
      MethodChannel(AppConstants.deviceChannel);

  /// Routes [payload] (from the command parser) to the right action.
  Future<DeviceActionResult> execute(String payload) async {
    try {
      if (payload == 'toggle_flashlight') return await _toggleFlashlight();

      if (payload.startsWith('call:')) {
        return _launchCall(payload.substring(5).trim());
      }
      if (payload.startsWith('sms:')) {
        return _launchSms(payload.substring(4).trim());
      }
      if (payload.startsWith('open:')) {
        return _openApp(payload.substring(5).trim());
      }
      if (payload.startsWith('reminder:')) {
        return const DeviceActionResult(
          success: true,
          spokenReply:
              'Reminder noted, Sir. I will keep it on record for this session.',
        );
      }

      return const DeviceActionResult(
        success: false,
        spokenReply: 'I could not interpret that action, Sir.',
      );
    } catch (e) {
      return DeviceActionResult(
        success: false,
        spokenReply: 'The action failed. $e',
      );
    }
  }

  Future<DeviceActionResult> _toggleFlashlight() async {
    try {
      final enabled = await _channel.invokeMethod<bool>('toggleFlashlight');
      return DeviceActionResult(
        success: true,
        spokenReply: enabled == true
            ? 'Flashlight activated.'
            : 'Flashlight deactivated.',
      );
    } on PlatformException catch (e) {
      return DeviceActionResult(
        success: false,
        spokenReply: 'I could not control the flashlight. ${e.message ?? ''}',
      );
    }
  }

  Future<DeviceActionResult> _launchCall(String target) async {
    // If target is not a number, open dialer with the raw name so the
    // user can confirm; numeric targets dial directly.
    final isNumber = RegExp(r'^[\d\s+\-()]+$').hasMatch(target);
    final uri = Uri(scheme: 'tel', path: target);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return DeviceActionResult(
      success: launched,
      spokenReply: launched
          ? (isNumber
              ? 'Calling $target now.'
              : 'Opening the dialer for $target. Please confirm the number.')
          : 'I was unable to place that call, Sir.',
    );
  }

  Future<DeviceActionResult> _launchSms(String target) async {
    final uri = Uri(scheme: 'sms', path: target);
    final launched = await launchUrl(uri);
    return DeviceActionResult(
      success: launched,
      spokenReply: launched
          ? 'Opening a message draft to $target.'
          : 'I could not open the messaging app, Sir.',
    );
  }

  Future<DeviceActionResult> _openApp(String name) async {
    final link = AppConstants.appAliases[name];
    if (link == null) {
      return DeviceActionResult(
        success: false,
        spokenReply: 'I do not have a registered handler for $name yet.',
      );
    }

    // Android settings intents go through the platform channel-free
    // "android.settings.*" scheme via ACTION_VIEW.
    if (link.startsWith('android.settings')) {
      final uri = Uri.parse('intent://$link#Intent;action=$link;end');
      final launched = await launchUrl(uri);
      return DeviceActionResult(
        success: launched,
        spokenReply: launched ? 'Opening $name.' : 'Could not open $name.',
      );
    }

    final uri = Uri.parse(link);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return DeviceActionResult(
      success: launched,
      spokenReply: launched ? 'Launching $name.' : 'Failed to launch $name.',
    );
  }

  /// Haptic feedback hook (native vibration).
  Future<void> vibrate([int ms = 40]) async {
    try {
      await _channel.invokeMethod('vibrate', {'ms': ms});
    } catch (_) {/* non-critical */}
  }
}