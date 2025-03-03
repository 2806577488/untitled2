import 'package:flutter/material.dart';

class OptimizedDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
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
  // 预构建菜单项（关键性能优化）
  late final List<DropdownMenuItem<T>> _prebuiltItems;

  @override
  void initState() {
    super.initState();
    _prebuiltItems = _buildMenuItems();
  }

  @override
  void didUpdateWidget(covariant OptimizedDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _prebuiltItems = _buildMenuItems();
    }
  }

  List<DropdownMenuItem<T>> _buildMenuItems() {
    return widget.items.map((item) {
      return DropdownMenuItem<T>(
        value: item,
        child: Text(
          item.toString(),
          style: const TextStyle(fontSize: 14),
        ),
      );
    }).toList(growable: false);
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
                    item.toString(),
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