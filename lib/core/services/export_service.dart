import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/history/data/history_models.dart';

/// Handles exporting a list of HistoryEntry to CSV or PDF and sharing
/// the resulting file via the platform share sheet. Kept in core/services
/// rather than features/history since Module 14 (Reports) will likely
/// want the same CSV/PDF export for weekly/monthly/adherence reports.
class ExportService {
  ExportService._();

  static Future<void> exportJsonBackup(
    Map<String, dynamic> payload, {
    String filename = 'smartmeds_backup.json',
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'SmartMeds — Backup',
    );
  }


  static String _formatDate(DateTime dt) => DateFormat('MMM d, yyyy').format(dt);
  static String _formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  static Future<void> exportToCsv(
    List<HistoryEntry> entries, {
    String filename = 'medicine_history',
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Medicine,Dosage,Scheduled Date,Scheduled Time,Status,Responded At');

    for (final e in entries) {
      final responded = e.respondedTime != null
          ? '${_formatDate(e.respondedTime!)} ${_formatTime(e.respondedTime!)}'
          : '';
      buffer.writeln(
        '"${e.medicineName}","${e.dosageLabel}","${_formatDate(e.scheduledTime)}",'
        '"${_formatTime(e.scheduledTime)}","${e.status.label}","$responded"',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'SmartMeds — Medicine History',
    );
  }

  static Future<void> exportToPdf(
    List<HistoryEntry> entries, {
    String filename = 'medicine_history',
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SmartMeds — Medicine History',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generated ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _headerCell('Medicine'),
                  _headerCell('Scheduled'),
                  _headerCell('Time'),
                  _headerCell('Status'),
                ],
              ),
              for (final e in entries)
                pw.TableRow(
                  children: [
                    _cell(e.medicineName),
                    _cell(_formatDate(e.scheduledTime)),
                    _cell(_formatTime(e.scheduledTime)),
                    _cell(e.status.label),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: '$filename.pdf');
  }

  static pw.Widget _headerCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      );

  static pw.Widget _cell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
      );
}
