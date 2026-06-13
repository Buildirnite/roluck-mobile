import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';

/// Muestra una hoja inferior para elegir el origen (galería o cámara) y
/// devuelve la imagen elegida, o null si el usuario cancela.
Future<File?> pickImageWithSheet(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.bgElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.accent),
            title: const Text('Galería',
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.accent),
            title: const Text('Cámara',
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final picked = await ImagePicker().pickImage(source: source);
  return picked == null ? null : File(picked.path);
}
