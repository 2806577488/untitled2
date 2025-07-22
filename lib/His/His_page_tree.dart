import 'package:flutter/material.dart';

class TreeNode {
  final String title;
  final List<TreeNode> children;
  bool isSelected;

  TreeNode({
    required this.title,
    this.children = const [],
    this.isSelected = false,
  });
}

class TreeListView extends StatelessWidget {
  final List<TreeNode> nodes;
  final int level;
  final ValueChanged<TreeNode>? onNodeSelected;
  final List<TreeNode> rootNodes;
  final ValueNotifier<List<TreeNode>> expandedNodes;

  const TreeListView({
    super.key,
    required this.nodes,
    required this.level,
    required this.rootNodes,
    required this.expandedNodes,
    this.onNodeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: nodes.map((node) => _TreeNodeWidget(
        node: node,
        level: level,
        nodes: nodes,
        rootNodes: rootNodes,
        expandedNodes: expandedNodes,
        onNodeSelected: onNodeSelected,
      )).toList(),
    );
  }
}

class _TreeNodeWidget extends StatefulWidget {
  final TreeNode node;
  final int level;
  final ValueChanged<TreeNode>? onNodeSelected;
  final List<TreeNode> nodes;
  final List<TreeNode> rootNodes;
  final ValueNotifier<List<TreeNode>> expandedNodes;

  const _TreeNodeWidget({
    required this.node,
    required this.level,
    required this.nodes,
    required this.rootNodes,
    required this.expandedNodes,
    this.onNodeSelected,
  });

  @override
  State<_TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends State<_TreeNodeWidget> {
  bool _isSelected = false;

  /// 辅助函数：替代已废弃的withOpacity
  static Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  List<TreeNode> _getAllNodes(List<TreeNode> nodes) {
    final List<TreeNode> allNodes = [];
    for (var node in nodes) {
      allNodes.add(node);
      allNodes.addAll(_getAllNodes(node.children));
    }
    return allNodes;
  }

  @override
  Widget build(BuildContext context) {
    final expanded = widget.expandedNodes.value.contains(widget.node);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 20,
            leading: widget.node.children.isEmpty
                ? const Icon(Icons.circle, size: 12, color: Colors.grey)
                : Icon(
              expanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              color: Colors.blue.shade800,
            ),
            title: Text(
              widget.node.title,
              style: TextStyle(
                fontSize: widget.level == 0 ? 16 : (widget.level == 1 ? 14 : 12),
                color: widget.level == 0 ? Colors.blue.shade800 : Colors.grey.shade800,
              ),
            ),
            selected: _isSelected,
            selectedTileColor: _withOpacity(Colors.lightBlue, 0.3),
            onTap: () {
              setState(() {
                if (widget.node.children.isEmpty) {
                  final allNodes = _getAllNodes(widget.rootNodes);
                  for (var n in allNodes) {
                    n.isSelected = false;
                  }
                  _isSelected = true;
                  widget.node.isSelected = true;
                  widget.onNodeSelected?.call(widget.node);
                } else {
                  if (expanded) {
                    widget.expandedNodes.value =
                        widget.expandedNodes.value.where((n) => n != widget.node).toList();
                  } else {
                    widget.expandedNodes.value = [...widget.expandedNodes.value, widget.node];
                  }
                }
              });
            },
          ),
        ),
        if (expanded && widget.node.children.isNotEmpty)
          TreeListView(
            nodes: widget.node.children,
            level: widget.level + 1,
            onNodeSelected: widget.onNodeSelected,
            rootNodes: widget.rootNodes,
            expandedNodes: widget.expandedNodes,
          ),
        const Divider(height: 1, color: Colors.grey, indent: 16, endIndent: 16),
      ],
    );
  }
}