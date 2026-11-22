import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_strings.dart';
import '../services/storage_service.dart';

class CompareScreen extends StatefulWidget {
  final String clientName;
  final List<File> allImages;
  final List<File> initialSelectedImages;

  const CompareScreen({
    super.key,
    required this.clientName,
    required this.allImages,
    required this.initialSelectedImages,
  });

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late List<File> _selectedImages;
  late List<TransformationController> _controllers;
  int _layoutIndex =
      0; // אינדקס התבנית הנבחרת מתוך התבניות הזמינות למספר התמונות
  final GlobalKey _comparisonKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _selectedImages = List.from(widget.initialSelectedImages);
    _controllers = List.generate(
        _selectedImages.length, (_) => TransformationController());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // הוספת משבצת תמונה (עד מקסימום 4)
  void _addSlot() {
    if (_selectedImages.length >= 4 || widget.allImages.isEmpty) return;
    setState(() {
      _selectedImages.add(widget.allImages.first);
      _controllers.add(TransformationController());
      _layoutIndex = 0;
    });
  }

  // הסרת משבצת תמונה (מינימום 2)
  void _removeSlot(int index) {
    if (_selectedImages.length <= 2) return;
    setState(() {
      _selectedImages.removeAt(index);
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _layoutIndex = 0;
    });
  }

  // החלפת תמונה במשבצת ספציפית
  Future<void> _pickImageForSlot(int slotIndex) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 190,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          itemCount: widget.allImages.length,
          itemBuilder: (context, index) {
            final img = widget.allImages[index];
            final date = StorageService.extractFormattedDate(img);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImages[slotIndex] = img;
                  _controllers[slotIndex].value = Matrix4.identity();
                });
                Navigator.pop(ctx);
              },
              child: Container(
                width: 110,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(img, fit: BoxFit.cover, width: 110),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(date, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _shareComparison() async {
    final s = AppStrings.of(context);
    setState(() => _isSharing = true);
    try {
      final boundary = _comparisonKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final shareFile = File(
          '${tempDir.path}/Skinaliz_${DateTime.now().millisecondsSinceEpoch}.png');
      await shareFile.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(shareFile.path)],
          text: s.shareText(widget.clientName));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // אייקוני תבניות התצוגה בהתאם לכמות התמונות (2, 3 או 4)
  List<IconData> _getAvailableTemplateIcons() {
    switch (_selectedImages.length) {
      case 2:
        return [
          Icons.view_column,
          Icons.view_agenda
        ]; // זה לצד זה | למעלה ולמטה
      case 3:
        return [
          Icons.view_week,
          Icons.view_quilt,
          Icons.dashboard
        ]; // 3 עמודות | 1+2 אנכי | 1+2 אופקי
      case 4:
      default:
        return [
          Icons.grid_view,
          Icons.view_week,
          Icons.view_quilt
        ]; // רשת 2x2 | 4 עמודות | 1 גדולה + 3
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final templateIcons = _getAvailableTemplateIcons();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.compareTitle),
        actions: [
          if (_selectedImages.length < 4 &&
              widget.allImages.length > _selectedImages.length)
            IconButton(
              onPressed: _addSlot,
              icon: const Icon(Icons.add_box_outlined),
            ),
          IconButton(
            onPressed: _isSharing ? null : _shareComparison,
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share),
          ),
        ],
      ),
      body: Column(
        children: [
          // סרגל בחירת תבנית תצוגה (Templates)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(templateIcons.length, (idx) {
                final isSelected = _layoutIndex == idx;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Icon(
                      templateIcons[idx],
                      color:
                          isSelected ? Colors.white : const Color(0xFF008080),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF008080),
                    onSelected: (_) => setState(() => _layoutIndex = idx),
                  ),
                );
              }),
            ),
          ),

          // אזור הקולאז' שיישמר וישותף כתמונה אחת
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: RepaintBoundary(
                  key: _comparisonKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio:
                              _selectedImages.length >= 3 && _layoutIndex == 1
                                  ? 1.35
                                  : 1.0,
                          child: _buildTemplateLayout(),
                        ),
                        // פס מיתוג תחתון
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          color: const Color(0xFF008080),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.clientName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Skinaliz',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: _isSharing ? null : _shareComparison,
              child: const Icon(Icons.share),
            ),
          ),
        ],
      ),
    );
  }

  // בניית הפריסה הדינמית לפי כמות התמונות והתבנית שנבחרה
  Widget _buildTemplateLayout() {
    final count = _selectedImages.length;

    if (count == 2) {
      if (_layoutIndex == 0) {
        // 2 תמונות: זה לצד זה
        return Row(
          children: [
            Expanded(child: _buildSlot(0)),
            Container(width: 2, color: Colors.white),
            Expanded(child: _buildSlot(1)),
          ],
        );
      } else {
        // 2 תמונות: למעלה ולמטה
        return Column(
          children: [
            Expanded(child: _buildSlot(0)),
            Container(height: 2, color: Colors.white),
            Expanded(child: _buildSlot(1)),
          ],
        );
      }
    }

    if (count == 3) {
      if (_layoutIndex == 0) {
        // 3 תמונות: 3 עמודות רצופות
        return Row(
          children: [
            Expanded(child: _buildSlot(0)),
            Container(width: 2, color: Colors.white),
            Expanded(child: _buildSlot(1)),
            Container(width: 2, color: Colors.white),
            Expanded(child: _buildSlot(2)),
          ],
        );
      } else if (_layoutIndex == 1) {
        // 3 תמונות: 1 גדולה בצד + 2 מוערמות בצד השני
        return Row(
          children: [
            Expanded(flex: 3, child: _buildSlot(0)),
            Container(width: 2, color: Colors.white),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(child: _buildSlot(1)),
                  Container(height: 2, color: Colors.white),
                  Expanded(child: _buildSlot(2)),
                ],
              ),
            ),
          ],
        );
      } else {
// 3 תמונות: 1 גדולה למעלה + 2 למטה
        return Column(
          children: [
            Expanded(flex: 3, child: _buildSlot(0)),
            Container(height: 2, color: Colors.white),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _buildSlot(1)),
                  Container(width: 2, color: Colors.white),
                  Expanded(child: _buildSlot(2)),
                ],
              ),
            ),
          ],
        );
      }
    }
// 4 תמונות
    if (_layoutIndex == 0) {
// רשת 2x2 קלאסית
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildSlot(0)),
                Container(width: 2, color: Colors.white),
                Expanded(child: _buildSlot(1)),
              ],
            ),
          ),
          Container(height: 2, color: Colors.white),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildSlot(2)),
                Container(width: 2, color: Colors.white),
                Expanded(child: _buildSlot(3)),
              ],
            ),
          ),
        ],
      );
    } else if (_layoutIndex == 1) {
// 4 עמודות רצופות (ציר זמן)
      return Row(
        children: [
          Expanded(child: _buildSlot(0)),
          Container(width: 2, color: Colors.white),
          Expanded(child: _buildSlot(1)),
          Container(width: 2, color: Colors.white),
          Expanded(child: _buildSlot(2)),
          Container(width: 2, color: Colors.white),
          Expanded(child: _buildSlot(3)),
        ],
      );
    } else {
// 1 גדולה + 3 קטנות בצד
      return Row(
        children: [
          Expanded(flex: 3, child: _buildSlot(0)),
          Container(width: 2, color: Colors.white),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _buildSlot(1)),
                Container(height: 2, color: Colors.white),
                Expanded(child: _buildSlot(2)),
                Container(height: 2, color: Colors.white),
                Expanded(child: _buildSlot(3)),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSlot(int index) {
    final file = _selectedImages[index];
    final date = StorageService.extractFormattedDate(file);
    final controller = _controllers[index];
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            transformationController: controller,
            minScale: 1.0,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: Image.file(file,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity),
          ),
// סרגל כלים קטן למשבצת (החלפת תמונה / איפוס זום / הסרת משבצת)
          Positioned(
            top: 4,
            left: 4,
            right: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _miniActionBtn(
                        Icons.swap_horiz, () => _pickImageForSlot(index)),
                    const SizedBox(width: 4),
                    _miniActionBtn(Icons.crop_free,
                        () => controller.value = Matrix4.identity()),
                  ],
                ),
                if (_selectedImages.length > 2)
                  _miniActionBtn(Icons.close, () => _removeSlot(index)),
              ],
            ),
          ),
// תאריך הצילום בתחתית
          Positioned(
            bottom: 6,
            left: 4,
            right: 4,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(date,
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniActionBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    );
  }
}
