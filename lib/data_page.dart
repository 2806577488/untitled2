import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column;
import 'package:universal_html/html.dart' as html;
import 'tools/error.dart';

class DataPage extends StatefulWidget {
  final String userId;
  final String loginLocation;

  const DataPage({
    super.key,
    required this.userId,
    required this.loginLocation,
  });

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据系统')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 添加一个按钮，放在最左侧
            ElevatedButton(
              onPressed: () async {
                try {
                  bool isSaved = await generateExcelTemplate();
                  // 提示用户文件已生成
                  if (isSaved && context.mounted) {
                    GlobalErrorHandler.showSuccess(
                      context: context,
                      message: '模板已生成并保存成功',
                      mounted: mounted,
                    );
                  }
                } catch (e, stack) {
                  if (context.mounted) {
                    GlobalErrorHandler.logAndShowError(
                      context: context,
                      exception: e,
                      stackTrace: stack,
                      title: '生成模板失败',
                      mounted: mounted,
                    );
                  }
                }
              },
              child: const Text('数据导入生成'),
            ),
            Text('用户 ID: ${widget.userId}'),
            Text('登录地点: ${widget.loginLocation}'),
            const Text('这是数据系统界面'),
          ],
        ),
      ),
    );
  }

  /// 生成Excel模板
  static Future<bool> generateExcelTemplate() async {
    // 创建新的工作簿
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // 设置表头
    sheet.getRangeByName('A1').setText('药品编码');
    sheet.getRangeByName('B1').setText('药品名称');
    sheet.getRangeByName('C1').setText('规格');
    sheet.getRangeByName('D1').setText('单位');
    sheet.getRangeByName('E1').setText('剂型');
    sheet.getRangeByName('F1').setText('包装规格');
    sheet.getRangeByName('G1').setText('包装单位');
    sheet.getRangeByName('H1').setText('零售价');
    sheet.getRangeByName('I1').setText('批发价');
    sheet.getRangeByName('J1').setText('成本价');
    sheet.getRangeByName('K1').setText('医保编码');
    sheet.getRangeByName('L1').setText('医保名称');
    sheet.getRangeByName('M1').setText('医保类型');
    sheet.getRangeByName('N1').setText('医保名称');
    sheet.getRangeByName('O1').setText('省统一编码');
    sheet.getRangeByName('P1').setText('病案费用类别');
    sheet.getRangeByName('Q1').setText('是否皮试药');
    sheet.getRangeByName('R1').setText('是否大输液');
    sheet.getRangeByName('S1').setText('是否毒麻药');
    sheet.getRangeByName('T1').setText('是否精神药');
    sheet.getRangeByName('U1').setText('是否贵重药');
    sheet.getRangeByName('V1').setText('是否抗菌素');
    sheet.getRangeByName('W1').setText('是否疫苗');
    sheet.getRangeByName('X1').setText('是否国基');
    sheet.getRangeByName('Y1').setText('是否省基');
    sheet.getRangeByName('Z1').setText('是否基数药');
    sheet.getRangeByName('AA1').setText('是否招标药');
    sheet.getRangeByName('AB1').setText('厂家');
    sheet.getRangeByName('AC1').setText('供应公司');
    sheet.getRangeByName('AD1').setText('批准文号');
    sheet.getRangeByName('AE1').setText('医保类型');
    sheet.getRangeByName('AF1').setText('医保名称');
    sheet.getRangeByName('AG1').setText('省统一编码');
    sheet.getRangeByName('AH1').setText('病案费用类别');
    sheet.getRangeByName('AI1').setText('是否皮试药');
    sheet.getRangeByName('AJ1').setText('是否大输液');
    sheet.getRangeByName('AK1').setText('是否毒麻药');
    sheet.getRangeByName('AL1').setText('是否精神药');
    sheet.getRangeByName('AM1').setText('是否贵重药');
    sheet.getRangeByName('AN1').setText('是否抗菌素');
    sheet.getRangeByName('AO1').setText('是否疫苗');
    sheet.getRangeByName('AP1').setText('是否国基');
    sheet.getRangeByName('AQ1').setText('是否省基');
    sheet.getRangeByName('AR1').setText('是否基数药');
    sheet.getRangeByName('AS1').setText('是否招标药');
    sheet.getRangeByName('AT1').setText('厂家');
    sheet.getRangeByName('AU1').setText('供应公司');
    sheet.getRangeByName('AV1').setText('批准文号');

    // 保存文件
    final bool isSaved = await saveExcel(
      workbook: workbook,
      defaultName: '数据导入模板',
    );
    return isSaved;
  }

  /// 保存Excel文件
  static Future<bool> saveExcel({
    required Workbook workbook,
    String defaultName = '未命名文件',
  }) async {
    final List<int> bytes = workbook.saveAsStream();

    try {
      if (kIsWeb) {
        // Web端保存
        final blob = html.Blob(
            [bytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        );
        final anchor = html.AnchorElement(
            href: html.Url.createObjectUrlFromBlob(blob)
        )
          ..setAttribute('download', '$defaultName.xlsx');
        anchor.click();
        return true;
      } else {
        // 桌面端保存
        final String? savePath = await FilePicker.platform.saveFile(
          dialogTitle: '选择保存位置',
          fileName: '$defaultName.xlsx',
          allowedExtensions: ['xlsx'],
          type: FileType.custom,
        );

        if (savePath != null) {
          final file = File(savePath);
          await file.writeAsBytes(bytes);
          return true;
        }
        return false; // 用户取消保存
      }
    } catch (e) {
      GlobalErrorHandler.logErrorOnly(e, StackTrace.current);
      rethrow;
    }
  }
}
