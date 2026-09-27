import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class RecentFilesService {
  RecentFilesService._();

  static Future<List<String>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(AppConstants.prefRecentFiles) ?? [];
    return list.where((path) => File(path).existsSync()).toList();
  }

  static Future<void> addRecentFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(AppConstants.prefRecentFiles) ?? [];
    current.remove(path);
    current.insert(0, path);

    if (current.length > AppConstants.maxRecentFiles) {
      current.removeRange(AppConstants.maxRecentFiles, current.length);
    }

    await prefs.setStringList(AppConstants.prefRecentFiles, current);
  }

  static Future<void> removeRecentFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(AppConstants.prefRecentFiles) ?? [];
    current.remove(path);
    await prefs.setStringList(AppConstants.prefRecentFiles, current);
  }

  static Future<void> clearRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefRecentFiles);
  }
}
