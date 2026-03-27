import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/transaction.dart';

class CsvExport {
  CsvExport._();

  /// 全データを CSV ファイルに書き出して Share Sheet を開く
  static Future<void> exportAndShare(List<Transaction> transactions) async {
    final buf = StringBuffer();

    // ヘッダー
    buf.writeln('日付,種別,カテゴリ,金額,メモ');

    // データ行（新しい順）
    final sorted = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final t in sorted) {
      final date =
          '${t.date.year}/${t.date.month.toString().padLeft(2, '0')}/${t.date.day.toString().padLeft(2, '0')}';
      final type = t.isIncome ? '収入' : '支出';
      final amount = t.amount.toInt().toString();
      // カンマ・ダブルクォートが含まれる場合はエスケープ
      final note = t.note.contains(',') || t.note.contains('"')
          ? '"${t.note.replaceAll('"', '""')}"'
          : t.note;
      buf.writeln('$date,$type,${t.category},$amount,$note');
    }

    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fname =
        'kakeibo_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
    final file = File('${dir.path}/$fname');
    // UTF-8 BOM 付きで書き出すと Excel が文字化けしない
    final bom = [0xEF, 0xBB, 0xBF];
    await file.writeAsBytes([...bom, ...utf8.encode(buf.toString())]);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: '家計メモ帳データ ($fname)',
    );
  }
}
