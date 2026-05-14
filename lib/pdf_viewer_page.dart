import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

class PdfViewerPage extends StatefulWidget {
  final String source;
  final PdfSourceType sourceType;
  final String? title;

  const PdfViewerPage.network(this.source, {super.key, this.title})
      : sourceType = PdfSourceType.network;
  const PdfViewerPage.file(this.source, {super.key, this.title})
      : sourceType = PdfSourceType.file;

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

enum PdfSourceType { network, file }

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfControllerPinch? _controller;
  int _pagesCount = 0;
  int _currentPage = 1;
  bool _loading = true;
  String? _error;
  final double _minScale = 1.0;
  final double _maxScale = 4.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.sourceType == PdfSourceType.file) {
        setState(() {
          _controller = PdfControllerPinch(
            document: PdfDocument.openFile(widget.source),
            initialPage: 1,
          );
          _loading = false;
        });
      } else {
        final uri = Uri.parse(widget.source);
        final resp = await http.get(uri);
        if (resp.statusCode != 200) {
          throw Exception('Failed to load PDF (${resp.statusCode})');
        }
        final bytes = Uint8List.fromList(resp.bodyBytes);
        setState(() {
          _controller = PdfControllerPinch(
            document: PdfDocument.openData(bytes),
            initialPage: 1,
          );
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'PDF';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_pagesCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_currentPage / $_pagesCount'),
              ),
            ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: (_controller != null && _currentPage > 1)
                ? () => _controller!.previousPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    )
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: (_controller != null && _currentPage < _pagesCount)
                ? () => _controller!.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeIn,
                    )
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error loading PDF:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_controller == null) {
      return const SizedBox.shrink();
    }
    return PdfViewPinch(
      controller: _controller!,
      backgroundDecoration: const BoxDecoration(color: Colors.black12),
      onDocumentLoaded: (doc) {
        setState(() {
          _pagesCount = doc.pagesCount;
        });
      },
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      minScale: _minScale,
      maxScale: _maxScale,
    );
  }

  Widget _buildBottomBar() {
    if (_controller == null || _pagesCount <= 1) {
      return const SizedBox(height: 0);
    }
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.pages, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _currentPage.toDouble(),
                    min: 1,
                    max: _pagesCount.toDouble(),
                    divisions: _pagesCount - 1,
                    label: 'Page $_currentPage',
                    onChanged: (v) {
                      final page = v.round();
                      if (page != _currentPage) {
                        _controller?.animateToPage(
                          pageNumber: page,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                      hintText: 'Go to',
                    ),
                    onSubmitted: (text) {
                      final page = int.tryParse(text.trim()) ?? _currentPage;
                      if (page >= 1 && page <= _pagesCount) {
                        _controller?.jumpToPage(page);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
