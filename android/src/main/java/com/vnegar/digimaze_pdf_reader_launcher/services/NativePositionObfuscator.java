package com.vnegar.digimaze_pdf_reader_launcher.services;

/**
 * پل ارتباطی به کد native برای الگوریتم PositionObfuscator.
 * منطق (SHA-256 seeding، LCG permutation) در C++ انجام میشه تا در برابر
 * دیکامپایل bytecode جاوا مقاوم‌تر باشه.
 */
final class NativePositionObfuscator {

    static {
        System.loadLibrary("paramdecryptor");
    }

    private NativePositionObfuscator() {
        // no instances
    }

    static native String deobfuscate(String key, boolean base64EncodeOutput, String obfuscated);
}
