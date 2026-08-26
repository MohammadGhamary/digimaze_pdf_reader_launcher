import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:digimaze_pdf_reader_launcher/extension/string_insert_extension.dart';
import 'package:digimaze_pdf_reader_launcher/models/dto/open_document_request.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/dto/sdk_license.dart';
import '../utils/utils.dart';
import 'exceptions/invalid_license_exception.dart';
import 'string_obfuscator.dart';

/// Builds the encrypted parameter payloads consumed by the native
/// (Android / Windows) PDF reader launchers.
///
/// NOTE ON WIRE FORMAT: fields are joined with [_kFieldSeparator] and the
/// resulting string is AES-256-CBC encrypted, then base64 encoded. The
/// "advanced" flow additionally re-inserts the outer [_kFinalSecretOffset]
/// key at a fixed character offset into the ciphertext's base64 form —
/// this is preserved exactly as-is because the native reader depends on
/// that offset to reconstruct the key. Don't change [_kFinalSecretOffset]
/// without updating the native side too.
///
/// Thank You
/// Mohammad Ghamari
///
class EncryptionService {
  static const String _kFieldSeparator = 'æ';
  static const int _kAesKeyBytes = 32; // AES-256
  static const int _kFinalSecretOffset = 14;

  static final _secureRandom = Random.secure();

  // ---------------------------------------------------------------------
  // Key generation
  // ---------------------------------------------------------------------

  static String _generateBase64Key() {
    final bytes = List<int>.generate(_kAesKeyBytes, (_) => _secureRandom.nextInt(256));
    return base64.encode(bytes);
  }

  static String _generateRandomString(int len) {
    return String.fromCharCodes(
      List.generate(len, (_) => _secureRandom.nextInt(33) + 89),
    );
  }

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------

  static Future<String> generateAdvancedPdfReaderParams(OpenDocumentRequest request) async {

    final password = request.pdfSource.password;
    final sdkLicense = request.sdkLicense;

    if (!request.pdfSource.isSample && password == null) {
      throw ArgumentError('OpenDocumentRequest.pdfSource.password is required');
    }

    if (sdkLicense == null) {
      throw ArgumentError('OpenDocumentRequest.sdkLicense is required');
    }

    final secret = _generateBase64Key();

    final obfuscatedPasswordsTask = _generateAndEncryptObfuscatedPasswords(secret, password ?? "sample");
    final encryptLicenseTask = _encryptLicenseData(secret, sdkLicense);
    final deviceUIDTask = Utils.getDeviceUid();
    final packageInfoTask = PackageInfo.fromPlatform();

    final (obfuscatedPasswords, (encKey, licKeyEnc, licSnEnc), deviceUID, packageInfo) =
    await (obfuscatedPasswordsTask, encryptLicenseTask, deviceUIDTask, packageInfoTask).wait;

    final pathEnc = await _encryptText(
      secret,
      "${request.pdfSource.filePath}***${obfuscatedPasswords[1]}",
    );

    final finalSecret = _generateBase64Key();
    final isSample = request.pdfSource.isSample;

    final fields = <String>[
      if (!isSample) packageInfo.version,
      if (!isSample) request.studyLogApiDetails!.logApiUrl,
      if (!isSample) deviceUID,
      request.pdfSource.bookId.toString(),
      request.pdfSource.title,
      if (!isSample) request.studyLogApiDetails!.authToken,
      pathEnc ?? '',
      encKey,
      licKeyEnc,
      obfuscatedPasswords[0] ?? '',
      obfuscatedPasswords[1] ?? '',
      obfuscatedPasswords[4] ?? '',
      obfuscatedPasswords[5] ?? '',
      obfuscatedPasswords[2] ?? '',
      licSnEnc,
      obfuscatedPasswords[3] ?? '',
      secret,
      isSample ? 'sample' : 'book',
    ];

    final raw = fields.join(_kFieldSeparator);

    final encrypted = await _encryptText(finalSecret, raw);
    if (encrypted == null) {
      throw StateError('Failed to encrypt PDF reader parameters');
    }

    final withFinalSecret = encrypted.insertAt(_kFinalSecretOffset, finalSecret);
    return base64.encode(utf8.encode(withFinalSecret));
  }

  static Future<String> generateClassicPdfReaderParams(
      OpenDocumentRequest request,
      ) async {
    final password = request.pdfSource.password;
    if (password == null) {
      throw ArgumentError('OpenDocumentRequest.pdfSource.password is required');
    }

    final secret = _generateBase64Key();

    final obfuscatedPasswords = await _generateAndEncryptObfuscatedPasswords(secret, password);

    final pathEnc = await _encryptText(
      secret,
      "${request.pdfSource.filePath.replaceAll('/', '\\')}***${obfuscatedPasswords[1]}",
    );
    if (pathEnc == null) {
      throw StateError('Failed to encrypt file path');
    }

    final originalParams = [
      pathEnc,
      obfuscatedPasswords[0] ?? '',
      pathEnc,
      obfuscatedPasswords[1] ?? '',
      obfuscatedPasswords[4] ?? '',
      obfuscatedPasswords[5] ?? '',
      obfuscatedPasswords[2] ?? '',
      obfuscatedPasswords[3] ?? '',
    ].join(_kFieldSeparator);

    return '"${base64.encode(utf8.encode(originalParams))}"';
  }

  // ---------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------

  static Future<List<String?>> _generateAndEncryptObfuscatedPasswords(
      String secret,
      String pass,
      ) async {
    final keys = List.generate(5, (_) => _generateRandomString(8));
    final mainOb = StringObfuscator(keys[0], base64EncodeOutput: true);
    final fakeObs = keys.sublist(1).map((k) => StringObfuscator(k, base64EncodeOutput: true)).toList();

    return Future.wait([
      _encryptText(secret, await fakeObs[0].obfuscate(_generateRandomString(pass.length))),
      _encryptText(secret, await fakeObs[1].obfuscate(_generateRandomString(pass.length))),
      _encryptText(secret, await fakeObs[2].obfuscate(_generateRandomString(pass.length))),
      _encryptText(secret, await fakeObs[3].obfuscate(_generateRandomString(8))),
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

    final encKey = results[0] ?? '';
    final licKeyEnc = results[1] ?? '';
    final licSnEnc = results[2] ?? '';

    if (encKey.isEmpty || licSnEnc.isEmpty || licKeyEnc.isEmpty) {
      throw InvalidLicException(
        message: 'در حال حاضر این کتابخوان در دسترس نمی باشد.',
      );
    }

    return (encKey, licKeyEnc, licSnEnc);
  }

  static Future<String?> _encryptText(String key, String text) async {
    try {
      final algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);

      final keyBytes = base64.decode(key);
      if (keyBytes.length != _kAesKeyBytes) {
        throw ArgumentError('Key must decode to $_kAesKeyBytes bytes, got ${keyBytes.length}');
      }
      final secretKey = await algorithm.newSecretKeyFromBytes(keyBytes);
      final nonce = algorithm.newNonce();

      final secretBox = await algorithm.encrypt(
        utf8.encode(text),
        secretKey: secretKey,
        nonce: nonce,
      );

      final combined = <int>[...nonce, ...secretBox.cipherText];
      return base64.encode(combined);
    } catch (e, st) {
      if (kDebugMode) {
        developer.log('Encryption error', error: e, stackTrace: st, name: 'EncryptionService');
      }
      return null;
    }
  }
}