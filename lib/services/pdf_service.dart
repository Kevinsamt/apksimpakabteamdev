import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateBorrowingPdf({
    required BuildContext context,
    required Map<String, dynamic> loanData,
    required String studentName,
    required String nim,
    required String kelas,
  }) async {
    try {
      final pdf = pw.Document();

      // Load logo
      final ByteData logoData = await rootBundle.load('assets/images/logo_student.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

      // Parse notes
      String semester = '-';
      String mk = '-';
      String dosen = '-';
      String pukul = '-';
      String tglPinjam = '-';
      String tglPraktik = '-';
      
      final String notes = loanData['notes'] ?? '';
      if (notes.contains('Semester:')) {
        final parts = notes.split(', ');
        for (var part in parts) {
          if (part.startsWith('Semester:')) semester = part.replaceFirst('Semester: ', '');
          if (part.startsWith('MK:')) mk = part.replaceFirst('MK: ', '');
          if (part.startsWith('Dosen:')) dosen = part.replaceFirst('Dosen: ', '');
          if (part.startsWith('Pukul:')) pukul = part.replaceFirst('Pukul: ', '');
          if (part.startsWith('Tgl Pinjam:')) tglPinjam = part.replaceFirst('Tgl Pinjam: ', '');
          if (part.startsWith('Tgl Praktik:')) tglPraktik = part.replaceFirst('Tgl Praktik: ', '');
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pc) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. Header Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Image(logoImage, height: 60),
                        ),
                        pw.Column(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('UNIVERSITAS\nSATYA TERRA BHINNEKA', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                            ),
                            pw.Divider(height: 1),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('FORMULIR', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                            ),
                            pw.Divider(height: 1),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('PEMINJAMAN DAN PENGEMBALIAN PERALATAN LABORATORIUM', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildHeaderInfo('Kode', 'FM/LBKB/01-01'),
                            pw.Divider(height: 1),
                            _buildHeaderInfo('Tanggal Berlaku', '28 Agustus 2023'),
                            pw.Divider(height: 1),
                            _buildHeaderInfo('Revisi', '-'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'FORMULIR PEMINJAMAN DAN PENGEMBALIAN PERALATAN LABORATORIUM\nPRODI D3 KEBIDANAN UNIVERSITAS SATYA TERRA BHINNEKA',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                ),
                pw.SizedBox(height: 24),

                // 3. Student Details
                _buildDetailRow('NAMA', studentName),
                _buildDetailRow('NIM', nim),
                _buildDetailRow('SEMESTER', semester),
                _buildDetailRow('MATA KULIAH', mk),
                _buildDetailRow('DOSEN PENGAMPU', dosen),
                _buildDetailRow('TANGGAL PINJAM', tglPinjam),
                _buildDetailRow('TANGGAL PRAKTIK', tglPraktik),
                _buildDetailRow('PUKUL', pukul),

                pw.SizedBox(height: 24),

                // 4. Main Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(30),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)))),
                        pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Peminjaman', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)))),
                        pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Pengembalian', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)))),
                        pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Kondisi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('1', style: const pw.TextStyle(fontSize: 9)))),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text(loanData['borrow_date']?.toString().split('T')[0] ?? '-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                              pw.Expanded(child: pw.Text(loanData['equipments']?['name'] ?? '-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                              pw.Expanded(child: pw.Text('1', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                            ],
                          ),
                        ),
                        pw.Text(''),
                        pw.Text(''),
                      ],
                    ),
                    for (var i = 0; i < 5; i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(''),
                        ],
                      ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Text(
                  'Atas pengajuan peminjaman alat-alat tersebut diatas, saya bertanggung jawab untuk mengembalikan alat-alat tersebut setelah selesai dipergunakan dalam keadaan baik dan lengkap.\nKami akan mematuhi tata tertib yang berlaku di laboratorium.',
                  style: const pw.TextStyle(fontSize: 9),
                ),

                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSignatureBox('Mengetahui,\nKa. Laboratorium'),
                    _buildSignatureBox('Dosen Mata Kuliah'),
                    _buildSignatureBox('Yang Meminjam'),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> generateReportsPdf({
    required BuildContext context,
    required int totalEquipments,
    required int availableEquipments,
    required int activeLoans,
    required int overdueLoans,
    required String summaryText,
  }) async {
    try {
      final pdf = pw.Document();

      // Load logo
      final ByteData logoData = await rootBundle.load('assets/images/logo_student.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pc) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Laporan Inventaris & Peminjaman', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Universitas Satya Terra Bhinneka', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('Tanggal Cetak: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Image(logoImage, height: 60),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 24),

                // Summary Stats
                pw.Text('Ringkasan Statistik', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                     _buildStatItem('Total Inventaris', totalEquipments.toString()),
                     _buildStatItem('Alat Tersedia', availableEquipments.toString()),
                     _buildStatItem('Pinjaman Aktif', activeLoans.toString()),
                     _buildStatItem('Terlambat', overdueLoans.toString()),
                  ],
                ),
                pw.SizedBox(height: 32),

                // Monthly Summary
                pw.Text('Analisis Grafik & Ringkasan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text(summaryText, style: const pw.TextStyle(fontSize: 11)),
                ),

                pw.Spacer(),
                pw.Divider(),
                pw.Center(child: pw.Text('Sistem Informasi Manajemen Peralatan & Alat Kebidanan (SIMPAKAB)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFE91E63))),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderInfo(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 3, child: pw.Text(label, style: const pw.TextStyle(fontSize: 8))),
          pw.Text(' : ', style: const pw.TextStyle(fontSize: 8)),
          pw.Expanded(flex: 4, child: pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          pw.Text(' : ', style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureBox(String title) {
    return pw.Column(
      children: [
        pw.Text(title, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 40),
        pw.Text('( _____________________ )', style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }
}
