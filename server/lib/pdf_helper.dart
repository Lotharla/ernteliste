import 'dart:io';
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
  
  Future<String> generatePDF(context) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Text('Hello, World!', style: const pw.TextStyle(fontSize: 20)),
        );
      },
    ));
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/example.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    // showDialog(
    //   context: context, 
    //   builder: (context) => AlertDialog(
    //     content: Text('PDF has been saved to $path'),
    //     actions: [
    //       TextButton(onPressed: () { Navigator.of(context).pop(); }, child: const Text('OK')),
    //     ],
    //   )
    // );
    return path;
  }
