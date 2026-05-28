import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// Renders the first page of a PDF SOAT to a PNG image so it can be fed to the
/// on-device OCR pipeline (ML Kit operates on raster images, not vector text).
@injectable
class SoatPdfRasterizer {
  const SoatPdfRasterizer();

  static const double _renderScale = 2.0;

  Future<File> rasterizeFirstPage(File pdf) async {
    final document = await PdfDocument.openFile(pdf.path);
    try {
      final page = await document.getPage(1);
      try {
        final image = await page.render(
          width: page.width * _renderScale,
          height: page.height * _renderScale,
          format: PdfPageImageFormat.png,
        );
        if (image == null) {
          throw const FileSystemException('Failed to rasterize PDF page');
        }
        final dir = await getTemporaryDirectory();
        final outFile = File(
          '${dir.path}/soat_scan_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await outFile.writeAsBytes(image.bytes);
        return outFile;
      } finally {
        await page.close();
      }
    } finally {
      await document.close();
    }
  }
}
