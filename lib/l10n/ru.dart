import 'app_strings.dart';

class RuStrings extends AppStrings {
  @override
  String get searchHint => 'Поиск клиента...';
  @override
  String get noClientsMsg => 'Нет клиентов.\nНажмите +, чтобы добавить.';
  @override
  String get newClientTitle => 'Новый клиент';
  @override
  String get clientNameLabel => 'Полное имя';
  @override
  String get editClientTitle => 'Изменить имя';
  @override
  String get deleteTitle => 'Удаление';
  @override
  String deleteClientConfirm(String name) => 'Удалить "$name" и все фото?';
  @override
  String deletePhotosConfirm(int count) => 'Удалить выбранные фото ($count)?';
  @override
  String get noImagesMsg => 'Нет фотографий';
  @override
  String selectedCount(int count) => 'Выбрано: $count';
  @override
  String get compareTitle => 'До / После';
  @override
  String get beforeLabel => 'До';
  @override
  String get afterLabel => 'После';
  @override
  String shareText(String name) => 'Прогресс лечения - $name | Skinaliz';
}
