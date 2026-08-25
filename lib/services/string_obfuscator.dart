import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class StringObfuscator {
  final String key;
  final bool base64EncodeOutput;

  StringObfuscator(this.key, {this.base64EncodeOutput = false});

  Future<int> _seedFromKeyAndLength(String key, int length) async {
    final bytes = utf8.encode(key);
    final sink = Sha256().newHashSink();
    sink.add(bytes);
    sink.close();

    final hash = await sink.hash();

    int seed = ((hash.bytes[0] & 0xFF) << 24) |
    ((hash.bytes[1] & 0xFF) << 16) |
    ((hash.bytes[2] & 0xFF) << 8) |
    (hash.bytes[3] & 0xFF);
    seed = seed & 0xFFFFFFFF;

    seed = (seed ^ ((length * 0x9E3779B1) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    return seed;
  }

  int _lcgNext(int state) {
    const int a = 1664525;
    const int c = 1013904223;
    final next = ((state * a + c) & 0xFFFFFFFF);
    return next;
  }

  Future<List<int>> _permutation(int length) async {
    if (length <= 1) return List<int>.generate(length, (i) => i);
    int state = await _seedFromKeyAndLength(key, length);
    final perm = List<int>.generate(length, (i) => i);
    for (int i = length - 1; i > 0; i--) {
      state = _lcgNext(state);
      final j = ((state >> 1) & 0x7FFFFFFF) % (i + 1);
      final tmp = perm[i];
      perm[i] = perm[j];
      perm[j] = tmp;
    }
    return perm;
  }

  List<int> _toCodePoints(String s) => s.runes.toList();
  String _fromCodePoints(List<int> codePoints) =>
      String.fromCharCodes(codePoints);

  Future<String> obfuscate(String input) async {
    if (input.isEmpty) return input;
    final cps = _toCodePoints(input);
    final perm = await _permutation(cps.length);
    final out = List<int>.filled(cps.length, 0);
    for (int i = 0; i < cps.length; i++) {
      out[i] = cps[perm[i]];
    }
    final outStr = _fromCodePoints(out);
    if (base64EncodeOutput) {
      return base64UrlEncode(utf8.encode(outStr));
    }
    return outStr;
  }

  Future<String> deobfuscate(String obfuscated) async {
    if (obfuscated.isEmpty) return obfuscated;
    String decoded = obfuscated;
    if (base64EncodeOutput) {
      try {
        decoded = utf8.decode(base64Url.decode(obfuscated));
      } catch (e) {
        throw FormatException('Base64 decode failed: $e');
      }
    }
    final cps = _toCodePoints(decoded);
    final perm = await _permutation(cps.length);
    final original = List<int>.filled(cps.length, 0);
    for (int dest = 0; dest < perm.length; dest++) {
      final src = perm[dest];
      original[src] = cps[dest];
    }
    return _fromCodePoints(original);
  }
}
