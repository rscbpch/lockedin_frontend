import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';

class AppAlertDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final String? cancelLabel;

  const AppAlertDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isTwoButton = cancelLabel != null;

    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, size: 16))),
      title: Text(
        title,
        style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 18), fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      content: message != null
          ? Text(
              message!,
              style: TextStyle(fontFamily: 'Quicksand', fontSize: Responsive.text(context, size: 16), color: AppColors.textPrimary),
            )
          : null,
      actions: [
        if (isTwoButton) ...[
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, size: 12))),
                  ),
                  child: Text(
                    cancelLabel!,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 14), fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, size: 12))),
                  ),
                  child: Text(
                    confirmLabel,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 14), fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, size: 12))),
              ),
              child: Text(
                confirmLabel,
                style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 14), fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }
}