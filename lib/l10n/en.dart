import 'app_strings.dart';

class EnStrings extends AppStrings {
  @override
  String get searchHint => 'Search client...';
  @override
  String get noClientsMsg => 'No clients yet.\nTap + to add a client.';
  @override
  String get newClientTitle => 'New Client';
  @override
  String get clientNameLabel => 'Full Name';
  @override
  String get editClientTitle => 'Edit Name';
  @override
  String get deleteTitle => 'Delete';
  @override
  String deleteClientConfirm(String name) => 'Delete "$name" and all photos?';
  @override
  String deletePhotosConfirm(int count) =>
      'Permanently delete $count photo(s)?';
  @override
  String get noImagesMsg => 'No photos yet';
  @override
  String selectedCount(int count) => '$count selected';
  @override
  String get compareTitle => 'Before / After';
  @override
  String get beforeLabel => 'Before';
  @override
  String get afterLabel => 'After';
  @override
  String shareText(String name) => 'Treatment Progress - $name | Skinaliz';
}
