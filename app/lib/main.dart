import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/services/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/timezone_utils.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 時區初始化（Asia/Taipei UTC+8）
  TimezoneUtils.init();

  // 2. Firebase 初始化
  await Firebase.initializeApp();

  // 3. Hive 本地資料庫初始化（偏鄉離線支援）
  await Hive.initFlutter();
  await _openHiveBoxes();

  // 4. 多語言初始化（easy_localization）
  await EasyLocalization.ensureInitialized();

  // 5. 系統 UI 設定
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 6. 啟動離線同步監聽
  SyncService.startListening();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('zh', 'TW'),
        Locale('id'),
        Locale('vi'),
        Locale('th'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('zh', 'TW'),
      startLocale: const Locale('zh', 'TW'),
      child: const ProviderScope(
        child: AnTsiSeCareApp(),
      ),
    ),
  );
}

Future<void> _openHiveBoxes() async {
  await Future.wait([
    Hive.openBox<Map>(AppConstants.hiveBoxCareLog),
    Hive.openBox<Map>(AppConstants.hiveBoxUser),
    Hive.openBox(AppConstants.hiveBoxSettings),
    Hive.openBox<Map>(AppConstants.hiveBoxLtcData),
    Hive.openBox<Map>(AppConstants.hiveBoxMedication),
  ]);
}

class AnTsiSeCareApp extends ConsumerWidget {
  const AnTsiSeCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // 讀取使用者設定（長者模式、暗色模式）
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final elderMode = settingsBox.get('elder_mode', defaultValue: false) as bool;
    final darkMode = settingsBox.get('dark_mode', defaultValue: false) as bool;

    return MaterialApp.router(
      title: AppConstants.appNameZh,
      debugShowCheckedModeBanner: false,

      // 主題
      theme: elderMode
          ? AppTheme.elderTheme(context)
          : AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,

      // 路由
      routerConfig: router,

      // 多語言
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
    );
  }
}
