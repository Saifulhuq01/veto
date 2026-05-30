import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../bridge/veto_method_channel.dart';

class BackupState {
  const BackupState({
    this.isExporting = false,
    this.isImporting = false,
    this.lastExportPath,
    this.lastError,
  });

  final bool isExporting;
  final bool isImporting;
  final String? lastExportPath;
  final String? lastError;

  BackupState copyWith({
    bool? isExporting,
    bool? isImporting,
    String? lastExportPath,
    String? lastError,
  }) {
    return BackupState(
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      lastExportPath: lastExportPath ?? this.lastExportPath,
      lastError: lastError,
    );
  }
}

class BackupNotifier extends StateNotifier<BackupState> {
  BackupNotifier() : super(const BackupState());

  final _channel = VetoMethodChannel();

  /// Export all app data to a JSON file and share it.
  Future<bool> exportData() async {
    state = state.copyWith(isExporting: true, lastError: null);
    try {
      final jsonStr = await _channel.exportAllData();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/veto_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Veto App Backup',
      );

      state = state.copyWith(
        isExporting: false,
        lastExportPath: file.path,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        lastError: e.toString(),
      );
      return false;
    }
  }

  /// Import data from a JSON backup file.
  Future<bool> importData() async {
    state = state.copyWith(isImporting: true, lastError: null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isImporting: false);
        return false;
      }

      final file = File(result.files.first.path!);
      final jsonStr = await file.readAsString();
      final success = await _channel.importAllData(jsonStr);

      state = state.copyWith(isImporting: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        lastError: e.toString(),
      );
      return false;
    }
  }
}

final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>(
  (ref) => BackupNotifier(),
);
