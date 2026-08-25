import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';

class Utils {
  static final bool isAndroid = Platform.isAndroid;
  static final bool isIos = Platform.isIOS;
  static final bool isWindows = Platform.isWindows;
  static final bool isLinux = Platform.isLinux;
  static final bool isMacOS = Platform.isMacOS;


  static bool get isDesktop => isWindows || isLinux || isMacOS;

  static bool get isMobile => !isDesktop;

  static Future<String> getDeviceUid() async{
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if(Utils.isAndroid) {
      const androidIdPlugin = AndroidId();
      final String? androidId = await androidIdPlugin.getId();
      return androidId ?? "NULL";
    }else if(Utils.isIos){
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor ?? "";
    }
    else if(Utils.isWindows) {
      WindowsDeviceInfo windowsDeviceInfo = await deviceInfo.windowsInfo;
      return windowsDeviceInfo.deviceId;
    }else{
      return "";
    }
  }

}
