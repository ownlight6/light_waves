import 'package:flutter/cupertino.dart';

class ThemeModel extends ChangeNotifier {
  String _theme = 'light';

  String get theme => _theme;

  void toggleTheme() {
    _theme = _theme == 'light' ? 'dark' : 'light';
    notifyListeners();
  }
}
