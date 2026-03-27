import 'package:flutter/material.dart';
import 'package:simpakab/services/pdf_service.dart';

class FormalFormView extends StatelessWidget {
  final Map<String, dynamic> loanData;
  final String studentName;
  final String nim;
  final String kelas;

  const FormalFormView({
    super.key,
    required this.loanData,
    required this.studentName,
    required this.nim,
    required this.kelas,
  });

  @override
  Widget build(BuildContext context) {
    // Parse notes to get formal details if available
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

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background like the user's image
      appBar: AppBar(
        title: const Text('Preview Formulir Formal', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: () => PdfService.generateBorrowingPdf(
            context: context,
            loanData: loanData,
              studentName: studentName,
              nim: nim,
              kelas: kelas,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Table
                Table(
                  border: TableBorder.all(color: Colors.black),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset('assets/images/logo_student.png', height: 60),
                        ),
                        const Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('UNIVERSITAS\nSATYA TERRA BHINNEKA', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            Divider(color: Colors.black, height: 1),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('FORMULIR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            Divider(color: Colors.black, height: 1),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('PEMINJAMAN DAN PENGEMBALIAN PERALATAN LABORATORIUM', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          ],
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeaderInfoRow(label: 'Kode', value: 'FM/LBKB/01-01'),
                            Divider(color: Colors.black, height: 1),
                            _HeaderInfoRow(label: 'Tanggal Berlaku', value: '28 Agustus 2023'),
                            Divider(color: Colors.black, height: 1),
                            _HeaderInfoRow(label: 'Revisi', value: '-'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'FORMULIR PEMINJAMAN DAN PENGEMBALIAN PERALATAN LABORATORIUM\nPRODI D3 KEBIDANAN UNIVERSITAS SATYA TERRA BHINNEKA',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 3. Student Details
                _DetailRow(label: 'NAMA', value: studentName),
                _DetailRow(label: 'NIM', value: nim),
                _DetailRow(label: 'SEMESTER', value: semester),
                _DetailRow(label: 'MATA KULIAH', value: mk),
                _DetailRow(label: 'DOSEN PENGAMPU', value: dosen),
                _DetailRow(label: 'TANGGAL PINJAM', value: tglPinjam),
                _DetailRow(label: 'TANGGAL PRAKTIK', value: tglPraktik),
                _DetailRow(label: 'PUKUL', value: pukul),
                
                const SizedBox(height: 24),
                
                // 4. Main Table
                Table(
                  border: TableBorder.all(color: Colors.black),
                  columnWidths: const {
                    0: FixedColumnWidth(30),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
                      children: [
                        TableCell(child: Center(child: Padding(padding: EdgeInsets.all(4.0), child: Text('No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))))),
                        TableCell(child: Center(child: Padding(padding: EdgeInsets.all(4.0), child: Text('Peminjaman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))))),
                        TableCell(child: Center(child: Padding(padding: EdgeInsets.all(4.0), child: Text('Pengembalian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))))),
                        TableCell(child: Center(child: Padding(padding: EdgeInsets.all(4.0), child: Text('Kondisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))))),
                      ],
                    ),
                    // Sub-headers
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
                      children: [
                        TableCell(child: SizedBox()),
                        TableCell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(child: Text('Tgl', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                              VerticalDivider(color: Colors.black),
                              Expanded(child: Text('Alat', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                              VerticalDivider(color: Colors.black),
                              Expanded(child: Text('Jml', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        TableCell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(child: Text('Tgl', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                              VerticalDivider(color: Colors.black),
                              Expanded(child: Text('Alat', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                              VerticalDivider(color: Colors.black),
                              Expanded(child: Text('Jml', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        TableCell(
                          child: Row(
                            children: [
                              Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                              VerticalDivider(color: Colors.black),
                              Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Data Row
                    TableRow(
                      children: [
                        const TableCell(child: Center(child: Padding(padding: EdgeInsets.all(4.0), child: Text('1', style: TextStyle(fontSize: 9))))),
                        TableCell(
                          child: Row(
                            children: [
                              Expanded(child: Text(loanData['borrow_date']?.toString().split('T')[0] ?? '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 8))),
                              Expanded(child: Text(loanData['equipments']?['name'] ?? '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 8))),
                              const Expanded(child: Text('1', textAlign: TextAlign.center, style: TextStyle(fontSize: 8))),
                            ],
                          ),
                        ),
                        const TableCell(child: Text('', textAlign: TextAlign.center)),
                        const TableCell(child: Text('', textAlign: TextAlign.center)),
                      ],
                    ),
                    // Empty spacer rows
                    for (var i = 0; i < 4; i++)
                      const TableRow(
                        children: [
                          TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text(''))),
                          TableCell(child: SizedBox()),
                          TableCell(child: SizedBox()),
                          TableCell(child: SizedBox()),
                        ],
                      ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Text(
                  'Atas pengajuan peminjaman alat-alat tersebut diatas, saya bertanggung jawab untuk mengembalikan alat-alat tersebut setelah selesai dipergunakan dalam keadaan baik dan lengkap.\nKami akan mematuhi tata tertib yang berlaku di laboratorium.',
                  style: TextStyle(fontSize: 9),
                ),
                
                const SizedBox(height: 40),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SignatureBox(title: 'Mengetahui,\nKa. Laboratorium'),
                    _SignatureBox(title: 'Dosen Mata Kuliah'),
                    _SignatureBox(title: 'Yang Meminjam'),
                  ],
                ),
                const SizedBox(height: 48),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => PdfService.generateBorrowingPdf(
                      context: context,
                      loanData: loanData,
                      studentName: studentName,
                      nim: nim,
                      kelas: kelas,
                    ),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text('Export to PDF', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 8))),
          const Text(' : ', style: TextStyle(fontSize: 8)),
          Expanded(flex: 4, child: Text(value, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
          const Text(' : ', style: TextStyle(fontSize: 9)),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 0.5))),
              child: Text(value, style: const TextStyle(fontSize: 9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureBox extends StatelessWidget {
  final String title;
  const _SignatureBox({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 60),
        const Text('( _____________________ )', style: TextStyle(fontSize: 9)),
      ],
    );
  }
}
