import 'app_strings.dart';

class HeStrings extends AppStrings {
  @override
  String get searchHint => 'חיפוש לקוח...';
  @override
  String get noClientsMsg => 'אין לקוחות להצגה.\nלחץ על + להוספת לקוח.';
  @override
  String get newClientTitle => 'לקוח חדש';
  @override
  String get clientNameLabel => 'שם מלא';
  @override
  String get editClientTitle => 'עריכת שם';
  @override
  String get deleteTitle => 'מחיקה';
  @override
  String deleteClientConfirm(String name) => 'למחוק את "$name" וכל התמונות?';
  @override
  String deletePhotosConfirm(int count) => 'למחוק $count תמונות לצמיתות?';
  @override
  String get noImagesMsg => 'אין תמונות עדיין';
  @override
  String selectedCount(int count) => '$count נבחרו';
  @override
  String get compareTitle => 'לפני / אחרי';
  @override
  String get beforeLabel => 'לפני';
  @override
  String get afterLabel => 'אחרי';
  @override
  String shareText(String name) => 'מעקב טיפול - $name | Skinaliz';
}
