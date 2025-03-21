import 'package:flutter/material.dart';

enum DialogButtonType { singleConfirm, confirmAndCancel }

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final DialogButtonType buttonType;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonType = DialogButtonType.singleConfirm,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 禁用返回键关闭
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // 内容区域（可滚动）
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SelectionArea(
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
            ),
            // 按钮区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.end,
      spacing: 8,
      children: buttonType == DialogButtonType.confirmAndCancel
          ? [
        _buildCancelButton(context),
        _buildConfirmButton(context),
      ]
          : [
        _buildConfirmButton(context),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: () => _handleConfirm(context),
      child: const Text("确定", style: TextStyle(color: Colors.blue)),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: () => _handleCancel(context),
      child: const Text("取消", style: TextStyle(color: Colors.grey)),
    );
  }

  void _handleConfirm(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
    onConfirm?.call();
  }

  void _handleCancel(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
    onCancel?.call();
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    DialogButtonType buttonType = DialogButtonType.singleConfirm,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    return showDialog<bool>(
      context: context,
      //barrierDismissible: false, // 禁用点击外部关闭
      useRootNavigator: true, // 使用根导航器
      builder: (context) => CustomDialog(
        title: title,
        content: content,
        buttonType: buttonType,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }
}
