import 'dart:io';
import 'package:camera/camera.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static Future<Directory> getRootDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final skinalizDir = Directory('${appDir.path}/skinaliz');
    if (!await skinalizDir.exists()) {
      await skinalizDir.create(recursive: true);
    }
    return skinalizDir;
  }

  static Future<List<Directory>> getClients() async {
    try {
      final root = await getRootDirectory();
      final entities = await root.list().toList();
      final dirs = entities.whereType<Directory>().toList();
      dirs.sort(
          (a, b) => getFolderName(a.path).compareTo(getFolderName(b.path)));
      return dirs;
    } catch (e) {
      debugPrint('Error loading clients: $e');
      return [];
    }
  }

  static Future<Directory> createClient(String clientName) async {
    final root = await getRootDirectory();
    final safeName = _sanitizeName(clientName);
    final clientDir = Directory('${root.path}/$safeName');
    if (!await clientDir.exists()) {
      await clientDir.create(recursive: true);
    }
    return clientDir;
  }

  static Future<Directory> renameClient(
      Directory currentDir, String newName) async {
    final root = await getRootDirectory();
    final safeName = _sanitizeName(newName);
    final newPath = '${root.path}/$safeName';

    if (currentDir.path == newPath) return currentDir;

    final targetDir = Directory(newPath);
    if (await targetDir.exists()) {
      throw Exception('Client "$safeName" already exists');
    }

    return await currentDir.rename(newPath);
  }

  static Future<void> deleteClient(Directory clientDir) async {
    if (await clientDir.exists()) {
      await clientDir.delete(recursive: true);
    }
  }

  static Future<List<File>> getClientImages(Directory clientDir) async {
    try {
      if (!await clientDir.exists()) return [];
      final entities = await clientDir.list().toList();
      final files = entities
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.jpg'))
          .toList();
      files.sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (e) {
      debugPrint('Error loading images: $e');
      return [];
    }
  }

  static Future<File> saveClientImage(
      Directory clientDir, XFile tempImage, String angleTag) async {
    final now = DateTime.now();
    final timestamp = _formatTimestamp(now);
    final fileName = '${timestamp}_$angleTag.jpg';
    final savedFile =
        await File(tempImage.path).copy('${clientDir.path}/$fileName');

    try {
      final tempFile = File(tempImage.path);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {}

    return savedFile;
  }

  static Future<int> importGalleryImages(
      Directory clientDir, List<XFile> pickedFiles) async {
    int count = 0;
    for (int i = 0; i < pickedFiles.length; i++) {
      final sourceFile = File(pickedFiles[i].path);
      if (await sourceFile.exists()) {
        final DateTime photoDate = await _extractExifDate(sourceFile);
        final timestamp = _formatTimestamp(photoDate);
        final fileName = '${timestamp}_Import_$i.jpg';
        await sourceFile.copy('${clientDir.path}/$fileName');
        count++;
      }
    }
    return count;
  }

  static Future<DateTime> _extractExifDate(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      final dateTag = data['EXIF DateTimeOriginal'] ??
          data['EXIF DateTimeDigitized'] ??
          data['Image DateTime'];

      if (dateTag != null) {
        final rawDate = dateTag.printable.trim();
        final parts = rawDate.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split(':');
          final timeParts = parts[1].split(':');
          if (dateParts.length == 3 && timeParts.length == 3) {
            return DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
              int.parse(timeParts[2]),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('EXIF read fallback: $e');
    }

    try {
      return await file.lastModified();
    } catch (_) {
      return DateTime.now();
    }
  }

  static Future<void> deleteImages(Iterable<String> filePaths) async {
    for (final path in filePaths) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  static String extractFormattedDate(File file) {
    final fileName = getFolderName(file.path);
    try {
      final datePart = fileName.split('_').first;
      final parts = datePart.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    final modified = file.lastModifiedSync();
    return '${_twoDigits(modified.day)}/${_twoDigits(modified.month)}/${modified.year}';
  }

  static String getFolderName(String fullPath) {
    return fullPath.split(RegExp(r'[/\\]')).last;
  }

  static String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}_${_twoDigits(dt.hour)}-${_twoDigits(dt.minute)}-${_twoDigits(dt.second)}';
  }

  static String _sanitizeName(String name) {
    return name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
