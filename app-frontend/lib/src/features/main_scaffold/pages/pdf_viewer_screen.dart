import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  String? _localFilePath;
  bool _isLoading = true;
  String _errorMessage = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      // 1. Get Temporary Directory
      final dir = await getTemporaryDirectory();

      // 2. Create a specific filename with .pdf extension
      // We use the current time to ensure uniqueness
      final fileName = "book_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final savePath = "${dir.path}/$fileName";

      debugPrint("Downloading to: $savePath");

      // 3. Download using Dio
      await Dio().download(
        widget.pdfUrl,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              _progress = count / total;
            });
          }
        },
      );

      // 4. Verify file exists and is not empty
      final file = File(savePath);
      if (await file.exists() && await file.length() > 0) {
        if (mounted) {
          setState(() {
            _localFilePath = savePath;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("File downloaded but is empty or missing.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Download Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B101D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFCFB56C)),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
                _localFilePath = null;
                _progress = 0.0;
              });
              _downloadAndSavePdf();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. PDF Viewer (Loads from File)
          if (_localFilePath != null)
            SfPdfViewer.file(
              File(_localFilePath!),
              key: _pdfViewerKey,
              enableDoubleTapZooming: true,
              pageLayoutMode:
                  PdfPageLayoutMode.continuous, // Best for scrolling
              canShowScrollHead: false, // Performance optimization
              canShowScrollStatus: true,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  _errorMessage =
                      "This file is corrupted or not a valid PDF.\n(${details.description})";
                  _localFilePath = null;
                });
              },
            ),

          // 2. Loading State
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    color: const Color(0xFFCFB56C),
                    backgroundColor: Colors.white10,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Downloading Book... ${(_progress * 100).toInt()}%",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

          // 3. Error State
          if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_outlined,
                        color: Colors.redAccent, size: 50),
                    const SizedBox(height: 16),
                    const Text(
                      "Error Opening Book",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = '';
                        });
                        _downloadAndSavePdf();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCFB56C),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Retry Download"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
