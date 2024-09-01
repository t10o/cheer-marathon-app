import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // Platformクラスを使用するためにインポート

Future<void> requestLocationPermission() async {
  PermissionStatus status;

  // Androidの場合
  if (Platform.isAndroid) {
    // 前景の位置情報権限をリクエスト
    status = await Permission.location.request();
    if (status.isGranted) {
      // 前景の位置情報権限が許可された場合、背景の位置情報権限をリクエスト
      status = await Permission.locationAlways.request();
    }
  }
  // iOSの場合
  else if (Platform.isIOS) {
    // 位置情報の「使用中」をリクエスト
    status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      // 「使用中」が許可された場合、「常に許可」をリクエスト
      status = await Permission.locationAlways.request();
    }
  } else {
    // サポートされていないプラットフォームの場合の処理
    print("このプラットフォームはサポートされていません");
    return;
  }

  // 許可が得られた場合の処理
  if (status.isGranted) {
    print("位置情報が常に許可されました");
  } else if (status.isDenied) {
    print("位置情報の権限が拒否されました");
  } else if (status.isPermanentlyDenied) {
    print("位置情報の権限が永久に拒否されました。設定から手動で許可を有効にしてください。");
    await openAppSettings();
  } else if (status.isRestricted) {
    print("位置情報の権限が制限されています。設定から手動で許可を有効にしてください。");
  } else {
    print("位置情報の権限のリクエストが失敗しました");
  }
}
