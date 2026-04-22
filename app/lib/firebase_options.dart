// firebase_options.dart — 使用 FlutterFire CLI 自動生成後替換此檔案
// 執行: flutterfire configure --project=your-firebase-project-id
//
// 暫時使用 placeholder，避免 CI/CD 將真實金鑰提交至版本庫。
// 正式部署時請使用 --dart-define 或 GitHub Secrets 注入環境變數。

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── 請替換為 Firebase Console 中取得的真實設定值 ──────────────────────────
  // Firebase Console → 專案設定 → 您的應用程式

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:000000000000:android:xxxxxxxxxxxxxxxx',
    messagingSenderId: '000000000000',
    projectId: 'antsicare-tw',
    storageBucket: 'antsicare-tw.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:xxxxxxxxxxxxxxxx',
    messagingSenderId: '000000000000',
    projectId: 'antsicare-tw',
    storageBucket: 'antsicare-tw.appspot.com',
    iosBundleId: 'tw.antsicare.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:000000000000:web:xxxxxxxxxxxxxxxx',
    messagingSenderId: '000000000000',
    projectId: 'antsicare-tw',
    storageBucket: 'antsicare-tw.appspot.com',
    authDomain: 'antsicare-tw.firebaseapp.com',
  );
}
