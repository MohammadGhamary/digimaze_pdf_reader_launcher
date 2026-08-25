import 'dart:convert';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:digimaze_pdf_reader_launcher/extension/string_insert_extension.dart';
import 'package:digimaze_pdf_reader_launcher/models/dto/open_document_request.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/dto/sdk_license.dart';
import '../utils/utils.dart';
import 'exceptions/invalid_license_exception.dart';
import 'string_obfuscator.dart';

class EncryptionService {
  static String _generateDynamicKey({int lengthInBytes = 32}) {
    final secureRandom = Random.secure();
    final values = List<int>.generate(
      lengthInBytes,
      (i) => secureRandom.nextInt(256),
    );
    return base64Url.encode(values);
  }

  static Future<String> generateAdvancedPdfReaderParams(
    OpenDocumentRequest request,
  ) async {
    final secret = _generateDynamicKey();

    final obfuscatedPasswords = await _generateAndEncryptObfuscatedPasswords(
      secret,
      request.pdfSource.password!,
    );

    final encryptLicenseTask = _encryptLicenseData(secret, request.sdkLicense!);
    final pathEncTask = _encryptText(
      secret,
      "${request.pdfSource.filePath}***${obfuscatedPasswords[1]}",
    );
    final deviceUIDTask = Utils.getDeviceUid();
    final packageInfoTask = PackageInfo.fromPlatform();

    final (
      (encKey, licKeyEnc, licSnEnc),
      pathEnc,
      deviceUID,
      packageInfo,
    ) = await (
      encryptLicenseTask,
      pathEncTask,
      deviceUIDTask,
      packageInfoTask,
    ).wait;

    String? encryptedParams;

    final finalSecret = _generateDynamicKey(lengthInBytes: 32);

    if (request.pdfSource.isSample) {
      final String raw =
          '${request.pdfSource.bookId}æ'
          '${request.pdfSource.title}æ'
          '$pathEncæ'
          '$encKeyæ'
          '$licKeyEncæ'
          '${obfuscatedPasswords[0]}æ'
          '${obfuscatedPasswords[1]}æ'
          '${obfuscatedPasswords[4]}æ'
          '${obfuscatedPasswords[5]}æ'
          '${obfuscatedPasswords[2]}æ'
          '$licSnEncæ'
          '${obfuscatedPasswords[3]}æ'
          '$secretæ'
          'sample';

      encryptedParams = await _encryptText(finalSecret, raw);
      encryptedParams = encryptedParams!.insertAt(14, finalSecret);
    } else {
      final String raw =
          '${packageInfo.version}æ'
          '${request.studyLogApiDetails!.logApiUrl}æ'
          '$deviceUIDæ'
          '${request.pdfSource.bookId}æ'
          '${request.pdfSource.title}æ'
          '${request.studyLogApiDetails!.authToken}æ'
          '$pathEncæ'
          '$encKeyæ'
          '$licKeyEncæ'
          '${obfuscatedPasswords[0]}æ'
          '${obfuscatedPasswords[1]}æ'
          '${obfuscatedPasswords[4]}æ'
          '${obfuscatedPasswords[5]}æ'
          '${obfuscatedPasswords[2]}æ'
          '$licSnEncæ'
          '${obfuscatedPasswords[3]}æ'
          '$secretæ'
          'book';

      String? encryptedParams = await _encryptText(finalSecret, raw);
      encryptedParams = encryptedParams!.insertAt(14, finalSecret);
    }

    return base64.encode(utf8.encode(encryptedParams!));
  }

  static Future<String> generateClassicPdfReaderParams(
    OpenDocumentRequest request,
  ) async {
    final secret = _generateDynamicKey();

    final obfuscatedPasswords = await _generateAndEncryptObfuscatedPasswords(
      secret,
      request.pdfSource.password!,
    );

    final pathEnc = await _encryptText(
      secret,
      "${request.pdfSource.filePath.replaceAll("/", "\\")}***${obfuscatedPasswords[1]}",
    );

    final String originalParams =
        '${pathEnc!}æ'
        '${obfuscatedPasswords[0]!}æ'
        '$pathEncæ'
        '${obfuscatedPasswords[1]!}æ'
        '${obfuscatedPasswords[4]!}æ'
        '${obfuscatedPasswords[5]!}æ'
        '${obfuscatedPasswords[2]!}æ'
        '${obfuscatedPasswords[3]!}æ';

    return '"${base64.encode(utf8.encode(originalParams))}"';
  }

  static String _generateRandomString(int len) {
    final r = Random();
    return String.fromCharCodes(List.generate(len, (_) => r.nextInt(33) + 89));
  }

  static Future<List<String?>> _generateAndEncryptObfuscatedPasswords(
    String secret,
    String pass,
  ) async {
    final keys = List.generate(5, (_) => _generateRandomString(8));
    final mainOb = StringObfuscator(keys[0], base64EncodeOutput: true);
    final fakeObs = keys
        .sublist(1)
        .map((k) => StringObfuscator(k, base64EncodeOutput: true))
        .toList();

    return Future.wait([
      _encryptText(
        secret,
        await fakeObs[0].obfuscate(_generateRandomString(pass.length)),
      ),
      _encryptText(
        secret,
        await fakeObs[1].obfuscate(_generateRandomString(pass.length)),
      ),
      _encryptText(
        secret,
        await fakeObs[2].obfuscate(_generateRandomString(pass.length)),
      ),
      _encryptText(
        secret,
        await fakeObs[3].obfuscate(_generateRandomString(8)),
      ),
      _encryptText(secret, await mainOb.obfuscate(pass)),
      _encryptText(secret, keys[0]),
    ]);
  }

  static Future<(String, String, String)> _encryptLicenseData(
    String secret,
    SdkLicense lic,
  ) async {
    final results = await Future.wait([
      _encryptText(secret, lic.encryptionKey),
      _encryptText(secret, lic.key),
      _encryptText(secret, lic.serialNumber),
    ]);

    final encKey = results[0] ?? "";
    final licKeyEnc = results[1] ?? "";
    final licSnEnc = results[2] ?? "";

    if (encKey.isEmpty || licSnEnc.isEmpty || licKeyEnc.isEmpty) {
      throw InvalidLicException(
        message: "در حال حاضر این کتابخوان در دسترس نمی باشد.",
      );
    }

    return (encKey, licKeyEnc, licSnEnc);
  }

  static Future<String?> _encryptText(String key, String text) async {
    try {
      final algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
      final keyString = _utf8ToHex(key);
      final keyBytes = utf8.encode(keyString);
      final ivString = _utf8ToHex(key.substring(0, 4), havePadding: true);
      final ivBytes = utf8.encode(ivString);
      final secretKey = await algorithm.newSecretKeyFromBytes(keyBytes);
      final clear = await algorithm.encrypt(
        utf8.encode(text),
        secretKey: secretKey,
        nonce: ivBytes,
      );

      final string = const Base64Encoder().convert(clear.cipherText);
      if (string.isEmpty) {
        return null;
      } else {
        return string;
      }
    } catch (e) {
      return null;
    }
  }

  static String _utf8ToHex(String str, {bool havePadding = false}) {
    var hexResult = "";

    for (final char in str.split("")) {
      var res = hex.encode(utf8.encode(char));
      if (res.length == 2 && havePadding) {
        res = "00$res";
      }
      hexResult += res;
    }
    return hexResult;
  }
}
