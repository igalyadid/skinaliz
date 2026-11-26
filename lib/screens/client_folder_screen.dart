import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_strings.dart';
import '../services/storage_service.dart';
import '../widgets/imageGrid_item.dart';
import 'camera_screen.dart';
import 'compare_screen.dart';

class ClientFolderScreen extends StatefulWidget {
  final Directory clientDir;
  const ClientFolderScreen({super.key, required this.clientDir});

  @override
  State<ClientFolderScreen> createState() => _ClientFolderScreenState();
}

class _ClientFolderScreenState extends State<ClientFolderScreen> {
  late Directory _currentClientDir;
  List<File> _images = [];
  bool _isLoading = true;
  final Set<String> _selectedPaths = {};
  final ImagePicker _picker = ImagePicker();

  String get _clientName =>
      StorageService.getFolderName(_currentClientDir.path);
  bool get _hasSelection => _selectedPaths.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _currentClientDir = widget.clientDir;
    _loadImages();
  }

  Future<void> _loadImages() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final imgs = await StorageService.getClientImages(_currentClientDir);
      if (mounted) {
        _images = imgs;
        _selectedPaths.removeWhere((p) => !_images.any((f) => f.path == p));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(String path) {
    setState(() {
      _selectedPaths.contains(path)
          ? _selectedPaths.remove(path)
          : _selectedPaths.add(path);
    });
  }

  Future<void> _importFromGallery() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      if (mounted) setState(() => _isLoading = true);
      await StorageService.importGalleryImages(_currentClientDir, picked);
      await _loadImages();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCompare({bool onlySelected = false}) async {
    List<File> selectedList;
    if (onlySelected &&
        _selectedPaths.length >= 2 &&
        _selectedPaths.length <= 4) {
      selectedList = _images
          .where((f) => _selectedPaths.contains(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    } else {
      selectedList = [_images.last, _images.first];
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareScreen(
          clientDir: _currentClientDir,
          clientName: _clientName,
          allImages: _images,
          initialSelectedImages: selectedList,
        ),
      ),
    );
    _loadImages();
  }

  Future<void> _deleteSelected() async {
    final s = AppStrings.of(context);
    final ok = await _showConfirmDialog(
        s.deleteTitle, s.deletePhotosConfirm(_selectedPaths.length));
    if (ok == true) {
      await StorageService.deleteImages(_selectedPaths);
      setState(() => _selectedPaths.clear());
      await _loadImages();
    }
  }

  Future<void> _editClientName() async {
    final s = AppStrings.of(context);
    final ctrl = TextEditingController(text: _clientName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.editClientTitle),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close)),
          IconButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty && newName != _clientName) {
                try {
                  final updated = await StorageService.renameClient(
                      _currentClientDir, newName);
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {
                    _currentClientDir = updated;
                    _selectedPaths.clear();
                  });
                  await _loadImages();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              } else {
                Navigator.pop(ctx);
              }
            },
            icon: const Icon(Icons.check, color: Color(0xFF008080)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClient() async {
    final s = AppStrings.of(context);
    final ok = await _showConfirmDialog(
        s.deleteTitle, s.deleteClientConfirm(_clientName));
    if (ok == true) {
      await StorageService.deleteClient(_currentClientDir);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          IconButton(
              onPressed: () => Navigator.pop(ctx, false),
              icon: const Icon(Icons.close)),
          IconButton(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: _hasSelection
          ? AppBar(
              backgroundColor: const Color(0xFF008080),
              foregroundColor: Colors.white,
              leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedPaths.clear())),
              title: Text(s.selectedCount(_selectedPaths.length)),
              actions: [
                if (_selectedPaths.length >= 2 && _selectedPaths.length <= 4)
                  IconButton(
                    onPressed: () => _openCompare(onlySelected: true),
                    icon: const Icon(Icons.compare),
                  ),
                IconButton(
                    onPressed: _deleteSelected, icon: const Icon(Icons.delete)),
              ],
            )
          : AppBar(
              title: Text(_clientName),
              actions: [
                if (_images.length >= 2)
                  IconButton(
                      onPressed: () => _openCompare(),
                      icon: const Icon(Icons.compare)),
                IconButton(
                    onPressed: _importFromGallery,
                    icon: const Icon(Icons.add_photo_alternate_outlined)),
                IconButton(
                    onPressed: _editClientName, icon: const Icon(Icons.edit)),
                IconButton(
                    onPressed: _deleteClient,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent)),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? Center(
                  child: Text(s.noImagesMsg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.only(
                      left: 12, right: 12, top: 12, bottom: 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final file = _images[index];
                    final dateStr = StorageService.extractFormattedDate(file);
                    return ImageGridItem(
                      file: file,
                      dateStr: dateStr,
                      isSelected: _selectedPaths.contains(file.path),
                      onTap: () => _hasSelection
                          ? _toggleSelection(file.path)
                          : _showPreview(file, dateStr),
                      onLongPress: () => _toggleSelection(file.path),
                      onToggleSelect: () => _toggleSelection(file.path),
                    );
                  },
                ),
      floatingActionButton: _hasSelection
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'importBtn',
                  onPressed: _importFromGallery,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF008080),
                  child: const Icon(Icons.photo_library),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'cameraBtn',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SkinalizCameraScreen(clientDir: _currentClientDir),
                      ),
                    );
                    _loadImages();
                  },
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            ),
    );
  }

  void _showPreview(File file, String dateStr) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.file(file))),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)),
                child:
                    Text(dateStr, style: const TextStyle(color: Colors.white)),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => Share.shareXFiles([XFile(file.path)],
                        text: s.shareText(_clientName)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
