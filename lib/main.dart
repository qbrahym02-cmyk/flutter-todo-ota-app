import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'services/remote_config.dart';
import 'services/task_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TaskStore();
  final config = RemoteConfig();
  await Future.wait([store.load(), config.init()]);
  runApp(TodoApp(store: store, config: config));
}

class TodoApp extends StatelessWidget {
  final TaskStore store;
  final RemoteConfig config;
  const TodoApp({super.key, required this.store, required this.config});

  @override
  Widget build(BuildContext context) {
    // اللون والعنوان يجون من السيرفر — أي تغيير يظهر فوراً
    return ListenableBuilder(
      listenable: config,
      builder: (context, _) => MaterialApp(
        title: config.appTitle,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorSchemeSeed: config.seedColor,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: config.seedColor,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: HomeScreen(store: store, config: config),
      ),
    );
  }
}
