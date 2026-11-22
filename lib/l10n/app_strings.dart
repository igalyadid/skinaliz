import 'package:flutter/material.dart';
import 'en.dart';
import 'he.dart';
import 'ru.dart';

abstract class AppStrings {
  static final Map<String, AppStrings> _languages = {
    'en': EnStrings(),
    'he': HeStrings(),
    'ru': RuStrings(),
  };

  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return _languages[code] ?? _languages['en']!;
  }

  String get appTitle => 'Skinaliz';
  String get searchHint;
  String get noClientsMsg;
  String get newClientTitle;
  String get clientNameLabel;
  String get editClientTitle;
  String get deleteTitle;
  String deleteClientConfirm(String name);
  String deletePhotosConfirm(int count);
  String get noImagesMsg;
  String selectedCount(int count);
  String get compareTitle;
  String get beforeLabel;
  String get afterLabel;
  String shareText(String name);
}
