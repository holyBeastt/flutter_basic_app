import 'package:flutter/material.dart';

class CustomToast {
  static void show(BuildContext context, String message, {bool isSuccess = false}) {
    print('CustomToast.show called - isSuccess: $isSuccess, message: $message');
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Xác định màu sắc và icon dựa trên isSuccess
    final Color backgroundColor = isSuccess ? Colors.green : Colors.red;
    final IconData iconData = isSuccess ? Icons.check_circle : Icons.error;
    
    print('Background color: $backgroundColor');
    print('Icon data: $iconData');

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 300),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    iconData,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Tự động ẩn sau 3 giây
    Future.delayed(Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Phương thức tiện ích cho thông báo thành công
  static void showSuccess(BuildContext context, String message) {
    print('CustomToast.showSuccess called with message: $message');
    show(context, message, isSuccess: true);
  }

  // Phương thức tiện ích cho thông báo lỗi
  static void showError(BuildContext context, String message) {
    print('CustomToast.showError called with message: $message');
    show(context, message, isSuccess: false);
  }
}
