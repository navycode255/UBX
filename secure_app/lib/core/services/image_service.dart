import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image service for handling profile pictures
class ImageService {
  static ImageService? _instance;
  final ImagePicker _picker = ImagePicker();

  ImageService._();
  
  static ImageService get instance {
    _instance ??= ImageService._();
    return _instance!;
  }

  /// Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Show image source selection dialog
  Future<File?> pickImageWithSource(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await pickImage(source: ImageSource.camera);
                  if (file != null) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Convert image file to base64 string
  Future<String?> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Convert base64 string to image file
  Future<File?> base64ToImage(String base64String, String fileName) async {
    try {
      final bytes = base64Decode(base64String);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(path.join(directory.path, fileName));
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  /// Save image to app documents directory
  Future<String?> saveImageToLocal(File imageFile, String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_$userId.jpg';
      final file = File(path.join(directory.path, fileName));
      
      // Copy the image to the app directory
      await imageFile.copy(file.path);
      
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Get local image file path
  Future<String?> getLocalImagePath(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_$userId.jpg';
      final file = File(path.join(directory.path, fileName));
      
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete local image file
  Future<bool> deleteLocalImage(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_$userId.jpg';
      final file = File(path.join(directory.path, fileName));
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Resize image to specific dimensions
  Future<File?> resizeImage(File imageFile, {int maxWidth = 400, int maxHeight = 400}) async {
    try {
      // For now, return the original file
      // In a real app, you'd use image processing libraries like image package
      return imageFile;
    } catch (e) {
      return null;
    }
  }

  /// Get image file from path
  File? getImageFile(String? imagePath) {
    if (imagePath != null && File(imagePath).existsSync()) {
      return File(imagePath);
    }
    return null;
  }
}
