import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class DataPage extends StatelessWidget {
  final String userId;
  final String loginLocation;

  const DataPage({
    super.key,
    required this.userId,
    required this.loginLocation,
  });

  Future<void> generateExcelTemplate() async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = "药品";

    // 只添加表头，不填充数据
    sheet.getRangeByName('A1').setText('医院内部编码');
    sheet.getRangeByName('B1').setText('项目名称');
    sheet.getRangeByName('C1').setText('通用名');
    sheet.getRangeByName('D1').setText('商品名');
    sheet.getRangeByName('E1').setText('规格');
    sheet.getRangeByName('F1').setText('基础分类');
    sheet.getRangeByName('G1').setText('发票分类');
    sheet.getRangeByName('H1').setText('项目类别');
    sheet.getRangeByName('I1').setText('药库进价');
    sheet.getRangeByName('J1').setText('药库零售价');
    sheet.getRangeByName('K1').setText('药库单位');
    sheet.getRangeByName('L1').setText('药库整散比');
    sheet.getRangeByName('M1').setText('药房零售价');
    sheet.getRangeByName('N1').setText('药房单位');
    sheet.getRangeByName('O1').setText('药房整散比');
    sheet.getRangeByName('P1').setText('使用单位');
    sheet.getRangeByName('Q1').setText('剂型');
    sheet.getRangeByName('R1').setText('默认门诊药房');
    sheet.getRangeByName('S1').setText('默认住院药房');
    sheet.getRangeByName('T1').setText('默认药库');
    sheet.getRangeByName('U1').setText('计价最小用量');
    sheet.getRangeByName('V1').setText('门诊整包装');
    sheet.getRangeByName('W1').setText('住院整包装');
    sheet.getRangeByName('X1').setText('默认用量');
    sheet.getRangeByName('Y1').setText('默认频率');
    sheet.getRangeByName('Z1').setText('默认用法');
    sheet.getRangeByName('AA1').setText('项目分类');
    sheet.getRangeByName('AB1').setText('是否可用');
    sheet.getRangeByName('AC1').setText('医保编码');
    sheet.getRangeByName('AD1').setText('医保类型');
    sheet.getRangeByName('AE1').setText('医保名称');
    sheet.getRangeByName('AF1').setText('省统一编码');
    sheet.getRangeByName('AG1').setText('病案费用类别');
    sheet.getRangeByName('AH1').setText('是否皮试药');
    sheet.getRangeByName('AI1').setText('是否大输液');
    sheet.getRangeByName('AJ1').setText('是否毒麻药');
    sheet.getRangeByName('AK1').setText('是否精神药');
    sheet.getRangeByName('AL1').setText('是否贵重药');
    sheet.getRangeByName('AM1').setText('是否抗菌素');
    sheet.getRangeByName('AN1').setText('是否疫苗');
    sheet.getRangeByName('AO1').setText('是否国基');
    sheet.getRangeByName('AP1').setText('是否省基');
    sheet.getRangeByName('AQ1').setText('是否基数药');
    sheet.getRangeByName('AR1').setText('是否招标药');
    sheet.getRangeByName('AS1').setText('厂家');
    sheet.getRangeByName('AT1').setText('供应公司');
    sheet.getRangeByName('AU1').setText('批准文号');

    // 保存文件
    final List<int> bytes = workbook.saveAsStream();
    //workbook.dispose();
    if (kIsWeb) {
      // Web环境下保存文件
      final html.Blob blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final html.AnchorElement anchor =
      html.AnchorElement(href: html.Url.createObjectUrlFromBlob(blob))
        ..setAttribute('download', '数据导入.xlsx');
      anchor.click();
    } else {
      final String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: '请选择保存位置',
        fileName: '数据导入.xlsx',
        allowedExtensions: ['xlsx'],
        type: FileType.custom,
      );
      if (savePath != null) {
        final File file = File(savePath);
        await file.writeAsBytes(bytes);
      }
    }
}

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
              await generateExcelTemplate();
              // 提示用户文件已生成
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据导入模板已生成')),
              );
            },
            child: const Text('数据导入生成'),
          ),
          Text('用户 ID: $userId'),
          Text('登录地点: $loginLocation'),
          const Text('这是数据系统界面'),
        ],
      ),
    ),
  );
}}
