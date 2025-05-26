import 'package:flutter/material.dart';
import 'His_page_data.dart';
import 'His_page_data_table.dart';

// 定义 TreeNode 类
class TreeNode {
  final String title;
  final List<TreeNode> children;

  TreeNode({required this.title, this.children = const []});
}

// 定义 TreeListView 组件
class TreeListView extends StatefulWidget {
  final List<TreeNode> nodes;
  final List<TreeNode> rootNodes;
  final ValueNotifier<List<TreeNode>> expandedNodes;
  final void Function(TreeNode node)? onNodeSelected;

  const TreeListView({
    super.key,
    required this.nodes,
    required this.rootNodes,
    required this.expandedNodes,
    this.onNodeSelected,
  });

  @override
  State<TreeListView> createState() => _TreeListViewState();
}

class _TreeListViewState extends State<TreeListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.nodes.length,
      itemBuilder: (context, index) {
        final node = widget.nodes[index];
        final isExpanded = widget.expandedNodes.value.contains(node);

        return Column(
          children: [
            ListTile(
              title: Row(
                children: [
                  if (node.children.isNotEmpty)
                    IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          widget.expandedNodes.value.remove(node);
                        } else {
                          widget.expandedNodes.value.add(node);
                        }
                      });
                    },
                  ),
                  if (node.children.isEmpty)
                    const SizedBox(width: 40),
                  Text(node.title),
                ],
              ),
              onTap: () {
                widget.onNodeSelected?.call(node);
              },
            ),
            if (isExpanded && node.children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: TreeListView(
                  nodes: node.children,
                  rootNodes: widget.rootNodes,
                  expandedNodes: widget.expandedNodes,
                  onNodeSelected: widget.onNodeSelected,
                ),
              ),
          ],
        );
      },
    );
  }
}


class HisPageBaseTable extends StatefulWidget {
  const HisPageBaseTable({super.key});

  @override
  State<HisPageBaseTable> createState() => _HisPageBaseTableState();
}

class _HisPageBaseTableState extends State<HisPageBaseTable> {
  bool _showData = true;
  Future<List<dynamic>>? _dataFuture;
  final List<TreeNode> _basicTableTreeData = [
    TreeNode(
      title: "用户信息基本表",
      children: [
        TreeNode(title: "省份"),
        TreeNode(title: "区/县"),
        TreeNode(title: "学历"),
        TreeNode(title: "民族"),
        TreeNode(title: "用户类别"),
        TreeNode(title: "记帐类别"),
        TreeNode(title: "用户大类"),
        TreeNode(title: "既往史维护"),
        TreeNode(title: "市/县"),
        TreeNode(title: "开发渠道"),
        TreeNode(title: "媒体渠道"),
      ],
    ),
  ];
  late ValueNotifier<List<TreeNode>> _expandedNodes;

  void _handleEdit(dynamic province) => print('编辑: ${province['Name']}');
  void _handleDelete(dynamic province) => print('删除: ${province['Name']}');
  void _handleSave() => print('保存数据');

  void _handleNodeSelected(TreeNode node) {
    if (node.title == "省份") {
      setState(() {
        _showData = true;
      });
    } else {
      setState(() {
        _showData = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _expandedNodes = ValueNotifier<List<TreeNode>>([]);
    _dataFuture = fetchProvinceData();
    _expandedNodes.value = [..._expandedNodes.value, _basicTableTreeData[0]];
  }

  @override
  void dispose() {
    _expandedNodes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 250,
          color: Colors.white,
          child: TreeListView(
            nodes: _basicTableTreeData,
            rootNodes: _basicTableTreeData,
            expandedNodes: _expandedNodes,
            onNodeSelected: _handleNodeSelected,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _showData && _dataFuture != null
                ? FutureBuilder<List<dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('错误: ${snapshot.error}'));
                }
                return DataTableWidget(
                  dataFuture: _dataFuture!,
                  onEdit: _handleEdit,
                  onDelete: _handleDelete,
                  onSave: _handleSave,
                );
              },
            )
                : Container(),
          ),
        ),
      ],
    );
  }
}