import 'dart:io';
import 'package:image_picker/image_picker.dart';

Future<String?> pickImage() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  return pickedFile?.path;
}
