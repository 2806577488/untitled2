import 'package:flutter/material.dart';

class OptimizedDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items; // 修改为接收原始数据列表
  final ValueChanged<T?>? onChanged;
  final String Function(T)? itemTextBuilder; // 新增文本构建器
  final String? hintText;
  final Widget? icon;
  final double menuMaxHeight;
  final Color? dropdownColor;
  final InputDecoration? decoration;

  const OptimizedDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.itemTextBuilder, // 新增参数
    this.hintText,
    this.icon,
    this.menuMaxHeight = 200,
    this.dropdownColor = Colors.white,
    this.decoration,
  });

  @override
  State<OptimizedDropdown<T>> createState() => _OptimizedDropdownState<T>();
}

class _OptimizedDropdownState<T> extends State<OptimizedDropdown<T>> {
  late List<DropdownMenuItem<T>> _prebuiltItems;

  @override
  void initState() {
    super.initState();
    _prebuiltItems = _buildMenuItems();
  }

  @override
  void didUpdateWidget(covariant OptimizedDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.itemTextBuilder != widget.itemTextBuilder) {
      _prebuiltItems = _buildMenuItems();
    }
  }

  List<DropdownMenuItem<T>> _buildMenuItems() {
    return widget.items.map<DropdownMenuItem<T>>((T item) {
      return DropdownMenuItem<T>(
        value: item, // 关键修复：使用当前item作为值
        child: Text(
          _getItemText(item),
          style: const TextStyle(fontSize: 14),
        ),
      );
    }).toList(growable: false);
  }

  String _getItemText(T item) {
    return widget.itemTextBuilder != null
        ? widget.itemTextBuilder!(item)
        : item.toString();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: widget.value,
      builder: (formFieldState) {
        return InputDecorator(
          decoration: (widget.decoration ?? const InputDecoration()).copyWith(
            prefixIcon: widget.icon,
            hintText: widget.hintText,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: widget.value,
              items: _prebuiltItems,
              isExpanded: true,
              menuMaxHeight: widget.menuMaxHeight,
              dropdownColor: widget.dropdownColor,
              borderRadius: BorderRadius.circular(8),
              iconSize: 24,
              elevation: 2,
              onChanged: (value) {
                widget.onChanged?.call(value);
                Future.microtask(() => formFieldState.didChange(value));
              },
              selectedItemBuilder: (context) {
                return widget.items.map((item) {
                  return Text(
                    _getItemText(item),
                    style: const TextStyle(fontSize: 14),
                  );
                }).toList();
              },
            ),
          ),
        );
      },
    );
  }
}