import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/document_upload_cubit.dart';
import 'document_upload_origin_row.dart';

/// Elegir de dónde sale el documento: cámara, galería o un PDF.
///
/// Nota de fidelidad: el `.pen` (`R9ZYe`) muestra esto como hoja modal
/// sobre la pantalla "Sin subir"; aquí se implementa como el primer paso
/// de la misma pantalla de subida por simplicidad de navegación — mismo
/// contenido y mismas acciones, sin el overlay oscuro de fondo.
///
/// Pencil: R9ZYe
class DocumentUploadOriginStep extends StatelessWidget {
  const DocumentUploadOriginStep({required this.vehicleId, super.key});

  final String vehicleId;

  Future<void> _fromCamera(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;
    await context.read<DocumentUploadCubit>().fileSelected(
      bytes,
      picked.path.split('.').last.toLowerCase(),
      imageFileForOcr: File(picked.path),
    );
  }

  Future<void> _fromGallery(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;
    await context.read<DocumentUploadCubit>().fileSelected(
      bytes,
      picked.path.split('.').last.toLowerCase(),
      imageFileForOcr: File(picked.path),
    );
  }

  Future<void> _fromPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    if (!context.mounted) return;
    await context.read<DocumentUploadCubit>().fileSelected(bytes, 'pdf');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.documents_upload_origin_title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.documents_upload_origin_subtitle,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 20),
          DocumentUploadOriginRow(
            icon: LucideIcons.camera,
            label: context.l10n.documents_origin_camera,
            onTap: () => _fromCamera(context),
          ),
          const SizedBox(height: 10),
          DocumentUploadOriginRow(
            icon: LucideIcons.image,
            label: context.l10n.documents_origin_gallery,
            onTap: () => _fromGallery(context),
          ),
          const SizedBox(height: 10),
          DocumentUploadOriginRow(
            icon: LucideIcons.fileText,
            label: context.l10n.documents_origin_pdf,
            onTap: () => _fromPdf(context),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.documents_privacy_note,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
