import 'package:flutter/material.dart';

class TreeNode {
  final String title;
  final List<TreeNode> children;

  TreeNode({required this.title, this.children = const []});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TreeNode &&
              runtimeType == other.runtimeType &&
              title == other.title;

  @override
  int get hashCode => title.hashCode;
}

class TreeView extends StatefulWidget {
  final List<TreeNode> nodes;
  final ValueChanged<TreeNode>? onNodeSelected;

  const TreeView({super.key, required this.nodes, this.onNodeSelected});

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  final Set<TreeNode> _expandedNodes = {};

  // 创建带透明度的颜色
  static Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 标题区域，背景颜色占满整个宽度，文本居中
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _withOpacity(const Color(0xFF1a2980), 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Text(
                "用户信息基本表",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // 树形内容区域
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.nodes.length,
              itemBuilder: (context, index) => _buildTreeNode(
                node: widget.nodes[index],
                depth: 0,
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildTreeNode({
    required TreeNode node,
    required int depth,
  }) {
    final isExpanded = _expandedNodes.contains(node);
    final hasChildren = node.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16 + depth * 20),
          leading: hasChildren
              ? IconButton(
            icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () => _toggleExpand(node),
          )
              : const SizedBox(width: 40),
          title: Text(
            node.title,
            style: TextStyle(
              fontSize: depth == 0 ? 16 : 14,
              fontWeight: depth == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () => widget.onNodeSelected?.call(node),
        ),
        if (isExpanded && hasChildren)
          Padding(
            padding: EdgeInsets.only(left: 16 + depth * 20),
            child: Column(
              children: node.children
                  .map((child) => _buildTreeNode(
                node: child,
                depth: depth + 1,
              ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _toggleExpand(TreeNode node) {
    setState(() {
      if (_expandedNodes.contains(node)) {
        _expandedNodes.remove(node);
      } else {
        _expandedNodes.add(node);
      }
    });
  }
}