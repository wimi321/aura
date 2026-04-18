import 'dart:convert';
import 'dart:io';

class AppPreferences {
  const AppPreferences({
    this.localeCode,
    this.activePresetId,
    this.recentCharacterIds = const <String>[],
  });

  final String? localeCode;
  final String? activePresetId;
  final List<String> recentCharacterIds;

  AppPreferences copyWith({
    String? localeCode,
    bool clearLocaleCode = false,
    String? activePresetId,
    bool clearActivePresetId = false,
    List<String>? recentCharacterIds,
  }) {
    return AppPreferences(
      localeCode: clearLocaleCode ? null : (localeCode ?? this.localeCode),
      activePresetId:
          clearActivePresetId ? null : (activePresetId ?? this.activePresetId),
      recentCharacterIds: recentCharacterIds ?? this.recentCharacterIds,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'localeCode': localeCode,
      'activePresetId': activePresetId,
      'recentCharacterIds': recentCharacterIds,
    };
  }

  factory AppPreferences.fromJson(Map<String, Object?> json) {
    return AppPreferences(
      localeCode: json['localeCode']?.toString(),
      activePresetId: json['activePresetId']?.toString(),
      recentCharacterIds:
          ((json['recentCharacterIds'] as List?) ?? const <Object>[])
              .map((Object? item) => item.toString())
              .where((String item) => item.trim().isNotEmpty)
              .toList(growable: false),
    );
  }
}

class AppPreferencesStore {
  const AppPreferencesStore(this._file);

  final File _file;

  Future<AppPreferences> load() async {
    if (!await _file.exists()) {
      return const AppPreferences();
    }

    try {
      final Object? decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map<String, Object?>) {
        return AppPreferences.fromJson(decoded);
      }
      if (decoded is Map) {
        return AppPreferences.fromJson(decoded.cast<String, Object?>());
      }
    } catch (_) {
      return const AppPreferences();
    }

    return const AppPreferences();
  }

  Future<void> save(AppPreferences preferences) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(preferences.toJson()),
    );
  }
}
