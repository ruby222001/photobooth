import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SSnackbarUtil {
  SSnackbarUtil._();

  static showSnackbar(String title, String message, SnackbarType? type,
      {int? duration}) {
    final bottomPadding = MediaQuery.of(Get.context!).padding.bottom;
    IconData? icon;
    Color color = Colors.grey.shade300;
    switch (type ?? SnackbarType.info) {
      case SnackbarType.info:
        color = Colors.black;
        break;
      case SnackbarType.warning:
        color = Colors.red.shade300;
        break;
      case SnackbarType.error:
        color = Colors.red.shade300;
        break;
      case SnackbarType.success:
        color = Colors.green.shade300;
        break;
      case SnackbarType.internet:
        color = Colors.grey.shade100;
        break;
    }
    switch (type ?? SnackbarType.info) {
      case SnackbarType.error:
      case SnackbarType.warning:
        icon = Icons.error;
        break;
      case SnackbarType.success:
        icon = Icons.check_circle;
        break;
      case SnackbarType.info:
        icon = Icons.info;
        break;
      case SnackbarType.internet:
        icon = Icons.wifi_off;
        break;
    }
    var newMessage = message.replaceAll(RegExp(r"^Exception:"), "");

    if (Get.context != null) {
      Get.rawSnackbar(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        // title,
        // message,
        borderRadius: 20,
        borderWidth: 1,
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        animationDuration: const Duration(milliseconds: 300),
        forwardAnimationCurve:
            type == SnackbarType.info ? Curves.easeIn : Curves.elasticIn,
        reverseAnimationCurve:
            type == SnackbarType.info ? Curves.easeOut : Curves.elasticIn,
        isDismissible: true,
        dismissDirection: DismissDirection.startToEnd,

        // title,
        message: newMessage,
        margin: EdgeInsets.fromLTRB(16, 40, 16, 0),

        icon: Icon(
          icon,
          color: Colors.white,
        ),

        duration: Duration(seconds: duration ?? 3),

        messageText: Text(
          newMessage,
          maxLines: 4,
          style: Get.textTheme.bodySmall!
              .copyWith(color: Get.theme.colorScheme.onPrimary),
        ),
        // borderRadius: 12,
        // borderWidth: 2,
        borderColor: color.withOpacity(0.8),
        barBlur: 1,

        backgroundColor: color,
      );
    } else {}
  }

  static showFadeSnackbar(
    BuildContext context,
    String message,
    SnackbarType? type,
  ) {
    Color color = Colors.grey.shade300;
    switch (type ?? SnackbarType.info) {
      case SnackbarType.info:
        color = Colors.black;
        break;
      case SnackbarType.warning:
        color = Colors.orange.shade300;
        break;
      case SnackbarType.error:
        color = Colors.red.shade300;
        break;
      case SnackbarType.success:
        color = Colors.green.shade300;
        break;
      case SnackbarType.internet:
        color = Colors.black;
        break;
    }
    final overlay = Overlay.of(Get.overlayContext!);
    if (overlay == null) {
      debugPrint('No overlay found');
      return;
    }
    final overlayEntry = OverlayEntry(
      builder: (_) {
        return Positioned(
          bottom: 60,
          left: 20,
          right: 20,
          child: FadeInSnackbar(
            message: message,
            color: color,
            type: type ?? SnackbarType.info,
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}

enum SnackbarType { info, warning, error, success, internet }

class FadeInSnackbar extends StatefulWidget {
  final String message;
  final Color color;
  final SnackbarType type;

  const FadeInSnackbar({
    super.key,
    required this.message,
    required this.color,
    required this.type,
  });

  @override
  State<FadeInSnackbar> createState() => _FadeInSnackbarState();
}

class _FadeInSnackbarState extends State<FadeInSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      _controller.reverse();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    IconData? icon;

    switch (widget.type) {
      case SnackbarType.error:
      case SnackbarType.warning:
        icon = Icons.error;
        break;
      case SnackbarType.success:
        icon = Icons.check_circle;
        break;
      case SnackbarType.info:
        icon = Icons.info;
        break;
      case SnackbarType.internet:
        icon = Icons.wifi_off;
        break;
    }

    return FadeTransition(
      opacity: _animation,
      child: Material(
        borderRadius: BorderRadius.circular(10),
        color: widget.color,
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  maxLines: 5,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}