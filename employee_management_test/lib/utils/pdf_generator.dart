import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/dto/payroll_dtos.dart';
import 'app_logger.dart';

/// 📄 PDF Generator for Payroll Documents
/// 
/// Features:
/// - Generate employee payslip (phiếu lương)
/// - Generate period payroll report (báo cáo lương kỳ)
/// - Preview PDF in app
/// - Save PDF to device
/// - Share PDF via system share sheet
/// 
/// ✅ Unicode Support:
/// - Uses Google Fonts (Roboto) via printing package
/// - Supports Vietnamese characters (Tiếng Việt)
class PayrollPdfGenerator {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');
  
  // ✅ Cache fonts to avoid reloading
  static pw.Font? _cachedFont;
  static pw.Font? _cachedBoldFont;
  
  /// Load Unicode fonts (Roboto from Google Fonts)
  static Future<void> _loadFonts() async {
    if (_cachedFont != null && _cachedBoldFont != null) {
      return; // Already loaded
    }
    
    AppLogger.debug('Loading Unicode fonts for PDF...', tag: 'PDF');
    
    // Load Roboto Regular and Bold from Google Fonts
    _cachedFont = await PdfGoogleFonts.robotoRegular();
    _cachedBoldFont = await PdfGoogleFonts.robotoBold();
    
    AppLogger.success('Fonts loaded successfully', tag: 'PDF');
  }

  /// Generate Employee Payslip PDF
  /// 
  /// Returns PDF document ready for preview/save
  static Future<pw.Document> generatePayslip({
    required PayrollRecordResponse record,
    required String periodName,
    String? companyName,
    String? companyAddress,
  }) async {
    AppLogger.startOperation('Generate Payslip PDF');
    
    // ✅ Load Unicode fonts first
    await _loadFonts();

    // ✅ Create theme with Unicode font
    final theme = pw.ThemeData.withFont(
      base: _cachedFont!,
      bold: _cachedBoldFont!,
    );

    final pdf = pw.Document(
      title: 'Phiếu lương - ${record.employeeName}',
      author: companyName ?? 'Company',
      creator: 'Employee Management System',
      theme: theme, // ✅ Apply theme with Unicode fonts
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: theme, // ✅ Apply theme to page
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(companyName, companyAddress),
              pw.SizedBox(height: 20),
              
              // Title
              pw.Center(
                child: pw.Text(
                  'PHIẾU LƯƠNG NHÂN VIÊN',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  periodName,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Employee Info
              _buildEmployeeInfo(record),
              pw.SizedBox(height: 20),
              
              // Salary Details
              _buildSalaryDetails(record),
              pw.SizedBox(height: 20),
              
              // Net Salary
              _buildNetSalary(record),
              pw.SizedBox(height: 30),
              
              // Signatures
              _buildSignatures(),
              
              pw.Spacer(),
              
              // Footer
              _buildFooter(record),
            ],
          );
        },
      ),
    );

    AppLogger.endOperation('Generate Payslip PDF', success: true);
    return pdf;
  }

  /// Generate Period Report PDF (All Employees)
  static Future<pw.Document> generatePeriodReport({
    required String periodName,
    required List<PayrollRecordResponse> records,
    required PayrollSummaryResponse summary,
    String? companyName,
  }) async {
    AppLogger.startOperation('Generate Period Report PDF');
    
    // ✅ Load Unicode fonts first
    await _loadFonts();
    
    // ✅ Create theme with Unicode font
    final theme = pw.ThemeData.withFont(
      base: _cachedFont!,
      bold: _cachedBoldFont!,
    );

    final pdf = pw.Document(
      title: 'Báo cáo lương - $periodName',
      author: companyName ?? 'Company',
      theme: theme, // ✅ Apply theme with Unicode fonts
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Landscape for wide table
        margin: const pw.EdgeInsets.all(30),
        theme: theme, // ✅ Apply theme to page
        build: (context) {
          return [
            // Header
            _buildHeader(companyName, null),
            pw.SizedBox(height: 15),
            
            // Title
            pw.Center(
              child: pw.Text(
                'BÁO CÁO LƯƠNG KỲ',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                periodName,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 15),
            
            // Summary
            _buildReportSummary(summary),
            pw.SizedBox(height: 15),
            
            // Data Table
            _buildReportTable(records),
            
            pw.SizedBox(height: 20),
            
            // Footer
            pw.Text(
              'Ngày in: ${_dateTimeFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    AppLogger.endOperation('Generate Period Report PDF', success: true);
    return pdf;
  }

  /// Preview PDF in App
  static Future<void> previewPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// Save PDF to Device
  /// Returns file path on success
  static Future<String?> savePdf({
    required pw.Document pdf,
    required String fileName,
  }) async {
    try {
      AppLogger.startOperation('Save PDF to Device');

      // Get downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Cannot access storage directory');
      }

      // Ensure .pdf extension
      if (!fileName.endsWith('.pdf')) {
        fileName = '$fileName.pdf';
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Save PDF bytes
      await file.writeAsBytes(await pdf.save());

      AppLogger.success('PDF saved to: $filePath', tag: 'PDF');
      AppLogger.endOperation('Save PDF to Device', success: true);

      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save PDF', error: e, stackTrace: stackTrace, tag: 'PDF');
      AppLogger.endOperation('Save PDF to Device', success: false);
      return null;
    }
  }

  /// Share PDF via System Share Sheet
  static Future<void> sharePdf({
    required pw.Document pdf,
    required String fileName,
  }) async {
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf',
    );
  }

  // ============ PRIVATE HELPER METHODS ============

  static pw.Widget _buildHeader(String? companyName, String? companyAddress) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          companyName ?? 'CÔNG TY CỔ PHẦN XYZ',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (companyAddress != null)
          pw.Text(
            companyAddress,
            style: const pw.TextStyle(fontSize: 10),
          ),
      ],
    );
  }

  static pw.Widget _buildEmployeeInfo(PayrollRecordResponse record) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'THÔNG TIN NHÂN VIÊN',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Họ và tên:', record.employeeName),
          _buildInfoRow('Mã số NV:', record.employeeId.toString()),
          _buildInfoRow('Số ngày làm việc:', '${record.totalWorkingDays} ngày'),
          _buildInfoRow('Giờ OT:', '${record.totalOTHours} giờ'),
        ],
      ),
    );
  }

  static pw.Widget _buildSalaryDetails(PayrollRecordResponse record) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CHI TIẾT LƯƠNG',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          
          // Income
          pw.Text('Thu nhập:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          _buildInfoRow('  Lương cơ bản', _currencyFormat.format(record.baseSalaryActual)),
          _buildInfoRow('  Lương OT', _currencyFormat.format(record.totalOTPayment)),
          _buildInfoRow('  Phụ cấp', _currencyFormat.format(record.totalAllowances)),
          _buildInfoRow('  Thưởng', _currencyFormat.format(record.bonus)),
          pw.Divider(thickness: 0.5),
          _buildInfoRow(
            '  Tổng thu nhập',
            _currencyFormat.format(record.adjustedGrossIncome),
            isBold: true,
          ),
          
          pw.SizedBox(height: 10),
          
          // Deductions
          pw.Text('Khấu trừ:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          _buildInfoRow('  BHXH/BHYT/BHTN', _currencyFormat.format(record.insuranceDeduction)),
          _buildInfoRow('  Thuế TNCN', _currencyFormat.format(record.pitDeduction)),
          _buildInfoRow('  Khác', _currencyFormat.format(record.otherDeductions)),
          pw.Divider(thickness: 0.5),
          _buildInfoRow(
            '  Tổng khấu trừ',
            _currencyFormat.format(
              record.insuranceDeduction + record.pitDeduction + record.otherDeductions,
            ),
            isBold: true,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNetSalary(PayrollRecordResponse record) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'LƯƠNG THỰC NHẬN:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            _currencyFormat.format(record.netSalary),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSignatureBox('Người lập phiếu'),
        _buildSignatureBox('Kế toán trưởng'),
        _buildSignatureBox('Giám đốc'),
      ],
    );
  }

  static pw.Widget _buildSignatureBox(String title) {
    return pw.Column(
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 40),
        pw.Container(
          width: 100,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(PayrollRecordResponse record) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (record.notes != null && record.notes!.isNotEmpty)
          pw.Text('Ghi chú: ${record.notes}', style: const pw.TextStyle(fontSize: 9)),
        pw.Text(
          'Ngày tính lương: ${_dateTimeFormat.format(record.calculatedAt)}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Text(
          'In lúc: ${_dateTimeFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReportSummary(PayrollSummaryResponse summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Tổng nhân viên', summary.totalEmployees.toString()),
          _buildSummaryItem('Tổng chi', _currencyFormat.format(summary.totalNetSalary)),
          _buildSummaryItem('Trung bình', _currencyFormat.format(
            summary.totalEmployees > 0 
              ? summary.totalNetSalary / summary.totalEmployees 
              : 0
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildReportTable(List<PayrollRecordResponse> records) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(50),
        4: const pw.FixedColumnWidth(50),
        5: const pw.FixedColumnWidth(80),
        6: const pw.FixedColumnWidth(80),
        7: const pw.FixedColumnWidth(80),
        8: const pw.FixedColumnWidth(90),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('STT', isHeader: true),
            _buildTableCell('MSNV', isHeader: true),
            _buildTableCell('Họ tên', isHeader: true),
            _buildTableCell('Ngày', isHeader: true),
            _buildTableCell('OT', isHeader: true),
            _buildTableCell('Thu nhập', isHeader: true),
            _buildTableCell('Khấu trừ', isHeader: true),
            _buildTableCell('Thưởng', isHeader: true),
            _buildTableCell('Thực nhận', isHeader: true),
          ],
        ),
        // Data rows
        ...records.asMap().entries.map((entry) {
          final index = entry.key;
          final record = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell((index + 1).toString()),
              _buildTableCell(record.employeeId.toString()),
              _buildTableCell(record.employeeName),
              _buildTableCell(record.totalWorkingDays.toString()),
              _buildTableCell(record.totalOTHours.toString()),
              _buildTableCell(_currencyFormat.format(record.adjustedGrossIncome)),
              _buildTableCell(_currencyFormat.format(
                record.insuranceDeduction + record.pitDeduction + record.otherDeductions,
              )),
              _buildTableCell(_currencyFormat.format(record.bonus)),
              _buildTableCell(_currencyFormat.format(record.netSalary)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
