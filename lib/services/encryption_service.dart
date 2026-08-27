import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:digimaze_pdf_reader_launcher/extension/string_insert_extension.dart';
import 'package:digimaze_pdf_reader_launcher/models/dto/open_document_request.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/dto/sdk_license.dart';
import '../utils/utils.dart';
import 'exceptions/encryption_exception.dart';
import 'exceptions/invalid_license_exception.dart';
import 'string_obfuscator.dart';

/// Builds the encrypted parameter payloads consumed by the native
/// (Android / Windows) PDF reader launchers.
///
/// ## Wire format
/// Fields are joined with [_kFieldSeparator] and the resulting string is
/// AES-256-CBC encrypted, then base64 encoded. The "advanced" flow
/// additionally re-inserts the outer [_kFinalSecretOffset] key at a fixed
/// character offset into the ciphertext's base64 form — this is preserved
/// exactly as-is because the native reader depends on that offset to
/// reconstruct the key. **Do not change [_kFinalSecretOffset], the field
/// separator, or the order of fields in either payload without making a
/// matching change on the native side.**
///
/// ## Field order (advanced payload)
/// For maintainability, the order below is the contract with the native
/// reader (see [generateAdvancedPdfReaderParams]):
/// 1. app version (non-sample only)
/// 2. study-log API URL (non-sample only)
/// 3. device UID (non-sample only)
/// 4. book id
/// 5. title
/// 6. study-log auth token (non-sample only)
/// 7. encrypted file path (+ decoy suffix)
/// 8. encrypted license encryption key
/// 9. encrypted license key
/// 10. decoy password field 1
/// 11. decoy password field 2
/// 12. encrypted, obfuscated real password
/// 13. encrypted password-obfuscation key
/// 14. decoy password field 3
/// 15. encrypted license serial number
/// 16. decoy password field 4
/// 17. the per-call AES secret used to encrypt everything above
/// 18. `"sample"` or `"book"`
///
/// ## Known security limitations (preserved intentionally)
/// The "classic" legacy payload (see [generateClassicPdfReaderParams])
/// uses a hardcoded, lightly XOR-obfuscated key and derives its IV
/// deterministically from that key rather than generating one randomly.
/// XOR obfuscation is not secrecy, and a fixed/predictable IV weakens
/// AES-CBC's semantic security guarantees. Both are kept exactly as-is
/// because the native reader depends on this exact derivation — do not
/// "fix" this here without coordinating a matching native-side change.
/// Treat the classic payload as a legacy compatibility path, not a model
/// for new work; new integrations should prefer [generateAdvancedPdfReaderParams].
///
/// Thank You
/// Mohammad Ghamari
///
class EncryptionService {
  static const String _kFieldSeparator = 'æ';
  static const int _kAesKeyBytes = 32; // AES-256
  static const int _kFinalSecretOffset = 14;

  /// [_generateRandomString] draws characters from a fixed 33-codepoint
  /// ASCII range (`_kRandomStringCodeBase` .. `_kRandomStringCodeBase +
  /// _kRandomStringCodeRange - 1`), matching the original implementation.
  static const int _kRandomStringCodeBase = 89;
  static const int _kRandomStringCodeRange = 33;

  /// Lightly obfuscated static key bytes for the legacy "classic" payload
  /// format (see class-level doc). XOR-obfuscation only prevents the key
  /// from appearing as a plain ASCII string in the compiled binary /
  /// decompiled source — treat this as a public constant, not a secret.
  static const List<int> _kClassicKeyObfuscatedBytes = [
    99, 81, 57, 65, 126, 62, 56, 43, 75, 58, 79, 127, 108, 59, 106, 122,
  ];
  static const int _kClassicKeyXorMask = 8;

  static final Random _secureRandom = Random.secure();

  // ---------------------------------------------------------------------
  // Key generation
  // ---------------------------------------------------------------------

  static String _generateBase64Key() {
    final bytes = Uint8List.fromList(
      List<int>.generate(_kAesKeyBytes, (_) => _secureRandom.nextInt(256)),
    );
    return base64.encode(bytes);
  }

  static String _generateRandomString(int length) {
    return String.fromCharCodes(
      List<int>.generate(
        length,
            (_) => _secureRandom.nextInt(_kRandomStringCodeRange) + _kRandomStringCodeBase,
      ),
    );
  }

  static String _resolveClassicKey() {
    final bytes = _kClassicKeyObfuscatedBytes
        .map((b) => b ^ _kClassicKeyXorMask)
        .toList(growable: false);
    return utf8.decode(bytes);
  }

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------

  /// Builds the "advanced" launch payload for a document open request.
  ///
  /// Throws [ArgumentError] if required request fields are missing,
  /// [InvalidLicException] if the SDK license fields fail to encrypt, and
  /// [EncryptionException] if any other required field fails to encrypt.
  static Future<String> generateAdvancedPdfReaderParams(OpenDocumentRequest request) async {
    final password = request.pdfSource.password;
    final sdkLicense = request.sdkLicense;
    final isSample = request.pdfSource.isSample;
    final studyLog = request.studyLogApiDetails;

    if (!isSample && password == null) {
      throw ArgumentError('OpenDocumentRequest.pdfSource.password is required for non-sample documents');
    }
    if (sdkLicense == null) {
      throw ArgumentError('OpenDocumentRequest.sdkLicense is required');
    }
    if (!isSample && studyLog == null) {
      throw ArgumentError('OpenDocumentRequest.studyLogApiDetails is required for non-sample documents');
    }

    final secret = _generateBase64Key();

    final passwordSetTask = _buildObfuscatedPasswordSet(secret, password ?? 'sample', useStaticPass: false);
    final licenseFieldsTask = _encryptLicenseData(secret, sdkLicense);
    final deviceUIDTask = Utils.getDeviceUid();
    final packageInfoTask = PackageInfo.fromPlatform();

    final (passwordSet, licenseFields, deviceUID, packageInfo) =
    await (passwordSetTask, licenseFieldsTask, deviceUIDTask, packageInfoTask).wait;

    final pathEnc = await _encryptTextOrThrow(
      secret,
      '${request.pdfSource.filePath}***${passwordSet.fake2}',
      fieldName: 'filePath',
    );

    final finalSecret = _generateBase64Key();

    // See the class-level "Field order" doc — this order is a contract
    // with the native reader and must not be changed casually.
    final fields = <String>[
      if (!isSample) packageInfo.version,
      if (!isSample) studyLog!.logApiUrl,
      if (!isSample) deviceUID,
      request.pdfSource.bookId.toString(),
      request.pdfSource.title,
      if (!isSample) studyLog!.authToken,
      pathEnc,
      licenseFields.encryptionKey,
      licenseFields.licenseKey,
      passwordSet.fake1,
      passwordSet.fake2,
      passwordSet.password,
      passwordSet.obfuscationKey,
      passwordSet.fake3,
      licenseFields.serialNumber,
      passwordSet.fake4,
      secret,
      isSample ? 'sample' : 'book',
    ];

    final raw = fields.join(_kFieldSeparator);
    final encrypted = await _encryptTextOrThrow(finalSecret, raw, fieldName: 'payload');

    final withFinalSecret = encrypted.insertAt(_kFinalSecretOffset, finalSecret);
    return base64.encode(utf8.encode(withFinalSecret));
  }

  /// Builds the legacy "classic" launch payload. See the class-level doc
  /// for the known security limitations of this path.
  ///
  /// Throws [ArgumentError] if required request fields are missing, and
  /// [EncryptionException] if any field fails to encrypt.
  static Future<String?> generateClassicPdfReaderParams(OpenDocumentRequest request) async {
    final password = request.pdfSource.password;

    if(Platform.isAndroid){
      final sdkLicense = request.sdkLicense;
      final isSample = request.pdfSource.isSample;

      if (!isSample && password == null) {
        throw ArgumentError('OpenDocumentRequest.pdfSource.password is required for non-sample documents');
      }

      if (sdkLicense == null) {
        throw ArgumentError('OpenDocumentRequest.sdkLicense is required');
      }

      final innerBlockSecret = _generateBase64Key();

      final passwordSetTask = _buildObfuscatedPasswordSet(innerBlockSecret, password ?? 'sample', useStaticPass: false);
      final licenseFieldsTask = _encryptLicenseData(innerBlockSecret, sdkLicense);

      final (passwordSet, licenseFields) = await (passwordSetTask, licenseFieldsTask).wait;

      final pathEnc = await _encryptTextOrThrow(
        innerBlockSecret,
        '${request.pdfSource.filePath}***${passwordSet.fake2}',
        fieldName: 'filePath',
      );

      final outerBlockSecret = _generateBase64Key();

      final fields = <String>[
        request.pdfSource.bookId.toString(),
        request.pdfSource.title,
        pathEnc,
        licenseFields.encryptionKey,
        licenseFields.licenseKey,
        passwordSet.fake1,
        passwordSet.fake2,
        passwordSet.password,
        passwordSet.obfuscationKey,
        passwordSet.fake3,
        licenseFields.serialNumber,
        passwordSet.fake4,
        innerBlockSecret,
        isSample ? 'sample' : 'book',
      ];

      final raw = fields.join(_kFieldSeparator);
      final encrypted = await _encryptTextOrThrow(outerBlockSecret, raw, fieldName: 'payload');

      final withFinalSecret = encrypted.insertAt(_kFinalSecretOffset, outerBlockSecret);
      return base64.encode(utf8.encode(withFinalSecret));

    }else if(Platform.isWindows){

      final secret = _resolveClassicKey();
      final passwordSet = await _buildObfuscatedPasswordSet(secret, password ?? '', useStaticPass: true);

      final pathEnc = await _encryptWithStaticPassOrThrow(
        secret,
        '${request.pdfSource.filePath}***${passwordSet.fake2}',
        fieldName: 'filePath',
      );

      final originalParams = <String>[
        pathEnc,
        passwordSet.fake1,
        passwordSet.fake2,
        passwordSet.password,
        passwordSet.obfuscationKey,
        passwordSet.fake3,
        passwordSet.fake4,
      ].join(_kFieldSeparator);

      return '"${base64.encode(utf8.encode(originalParams))}"';
    }else{
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------

  /// Builds the six password-related fields shared by both payload
  /// formats: four decoys, the real (obfuscated, encrypted) password, and
  /// the encrypted key used to obfuscate it. [useStaticPass] selects
  /// which underlying encryption routine ([_encryptText] for the advanced
  /// payload's per-call random key, or [_encryptWithStaticPass] for the
  /// classic payload's static key) is used for every field, matching the
  /// original implementation's split between the two flows.
  static Future<_ObfuscatedPasswordSet> _buildObfuscatedPasswordSet(
      String secret,
      String password, {
        required bool useStaticPass,
      }) async {
    final keys = List<String>.generate(5, (_) => _generateRandomString(8));
    final mainObfuscator = StringObfuscator(keys[0], base64EncodeOutput: true);
    final fakeObfuscators = keys
        .sublist(1)
        .map((k) => StringObfuscator(k, base64EncodeOutput: true))
        .toList(growable: false);

    Future<String> encrypt(String plainText, String fieldName) => useStaticPass
        ? _encryptWithStaticPassOrThrow(secret, plainText, fieldName: fieldName)
        : _encryptTextOrThrow(secret, plainText, fieldName: fieldName);

    final results = await Future.wait<String>([
      encrypt(await fakeObfuscators[0].obfuscate(_generateRandomString(password.length)), 'password.fake1'),
      encrypt(await fakeObfuscators[1].obfuscate(_generateRandomString(password.length)), 'password.fake2'),
      encrypt(await fakeObfuscators[2].obfuscate(_generateRandomString(password.length)), 'password.fake3'),
      encrypt(await fakeObfuscators[3].obfuscate(_generateRandomString(8)), 'password.fake4'),
      encrypt(await mainObfuscator.obfuscate(password), 'password.main'),
      encrypt(keys[0], 'password.obfuscationKey'),
    ]);

    return _ObfuscatedPasswordSet(
      fake1: results[0],
      fake2: results[1],
      fake3: results[2],
      fake4: results[3],
      password: results[4],
      obfuscationKey: results[5],
    );
  }

  static Future<_LicenseFields> _encryptLicenseData(String secret, SdkLicense lic) async {
    try {
      final results = await Future.wait<String>([
        _encryptTextOrThrow(secret, lic.encryptionKey, fieldName: 'license.encryptionKey'),
        _encryptTextOrThrow(secret, lic.key, fieldName: 'license.key'),
        _encryptTextOrThrow(secret, lic.serialNumber, fieldName: 'license.serialNumber'),
      ]);
      return _LicenseFields(encryptionKey: results[0], licenseKey: results[1], serialNumber: results[2]);
    } on EncryptionException {
      throw InvalidLicException(
        message: 'در حال حاضر این کتابخوان در دسترس نمی باشد.',
      );
    }
  }

  /// Encrypts [text] with [key] using the advanced flow's AES-256-CBC +
  /// random-nonce scheme, or throws [EncryptionException] naming
  /// [fieldName] if encryption fails. Prefer this over calling
  /// [_encryptText] directly for any field the payload cannot do without.
  static Future<String> _encryptTextOrThrow(String key, String text, {required String fieldName}) async {
    final result = await _encryptText(key, text);
    if (result == null) {
      throw EncryptionException('Failed to encrypt field "$fieldName"');
    }
    return result;
  }

  /// As [_encryptTextOrThrow], but for the classic flow's static-key
  /// scheme (see [_encryptWithStaticPass]).
  static Future<String> _encryptWithStaticPassOrThrow(String key, String text, {required String fieldName}) async {
    final result = await _encryptWithStaticPass(key, text);
    if (result == null) {
      throw EncryptionException('Failed to encrypt field "$fieldName"');
    }
    return result;
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
      _logEncryptionFailure('_encryptText', e, st);
      return null;
    }
  }

  /// **Known weakness (preserved for native-side compatibility):** the IV
  /// here is derived deterministically from the first 4 characters of
  /// [key] rather than being randomly generated per call, and in the
  /// classic flow [key] itself is a hardcoded, lightly-obfuscated
  /// constant (see [_resolveClassicKey]). Neither meets modern AES-CBC
  /// guidance — a fixed/predictable IV and a non-secret key both weaken
  /// the scheme's security guarantees. This is kept exactly as-is because
  /// the native Android/Windows reader depends on this exact derivation.
  /// Do not change this without a matching native-side change; consider
  /// planning a migration to a random IV + securely provisioned key for a
  /// future protocol version instead.
  static Future<String?> _encryptWithStaticPass(String key, String text) async {
    try {
      print(text);
      final algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
      final keyBytes = utf8.encode(_utf8ToHex(key));
      final ivBytes = utf8.encode(_utf8ToHex(key.substring(0, 4), havePadding: true));
      final secretKey = await algorithm.newSecretKeyFromBytes(keyBytes);

      final result = await algorithm.encrypt(
        utf8.encode(text),
        secretKey: secretKey,
        nonce: ivBytes,
      );

      final encoded = base64.encode(result.cipherText);
      return encoded.isEmpty ? null : encoded;
    } catch (e, st) {
      _logEncryptionFailure('_encryptWithStaticPass', e, st);
      return null;
    }
  }

  static void _logEncryptionFailure(String source, Object error, StackTrace stackTrace) {
    // Never log `key`/`text` here — only the error and call site. Those
    // two arguments may contain secrets or plaintext passwords.
    if (kDebugMode) {
      developer.log('Encryption error in $source', error: error, stackTrace: stackTrace, name: 'EncryptionService');
    }
  }

  static String _utf8ToHex(String str, {bool havePadding = false}) {
    final buffer = StringBuffer();
    for (final char in str.split('')) {
      var encoded = hex.encode(utf8.encode(char));
      if (havePadding && encoded.length == 2) {
        encoded = '00$encoded';
      }
      buffer.write(encoded);
    }
    return buffer.toString();
  }
}

/// The four decoy fields plus the real password and its obfuscation key,
/// as produced by [EncryptionService._buildObfuscatedPasswordSet]. Field
/// names replace the original implementation's positional list indices
/// (`obfuscatedPasswords[0]`..`[5]`) to make the field-assembly code in
/// [EncryptionService.generateAdvancedPdfReaderParams] and
/// [EncryptionService.generateClassicPdfReaderParams] self-documenting.
class _ObfuscatedPasswordSet {
  const _ObfuscatedPasswordSet({
    required this.fake1,
    required this.fake2,
    required this.fake3,
    required this.fake4,
    required this.password,
    required this.obfuscationKey,
  });

  /// Legacy array index 0.
  final String fake1;

  /// Legacy array index 1. Also reused as a decoy suffix appended to the
  /// encrypted file path field in both payload formats.
  final String fake2;

  /// Legacy array index 2.
  final String fake3;

  /// Legacy array index 3.
  final String fake4;

  /// Legacy array index 4 — the encrypted, obfuscated real password.
  final String password;

  /// Legacy array index 5 — the encrypted key used to obfuscate [password].
  final String obfuscationKey;
}

/// The three encrypted SDK license fields, as produced by
/// [EncryptionService._encryptLicenseData].
class _LicenseFields {
  const _LicenseFields({
    required this.encryptionKey,
    required this.licenseKey,
    required this.serialNumber,
  });

  final String encryptionKey;
  final String licenseKey;
  final String serialNumber;
}