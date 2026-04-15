import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';

class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final Uint8List bytes = args['bytes'] as Uint8List;
    final String title = (args['title'] as String?) ?? 'Invoice PDF';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        onError: (context, error) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(
                'Could not load PDF',
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
