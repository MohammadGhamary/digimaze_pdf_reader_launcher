package com.vnegar.digimaze_pdf_reader_launcher.services;

final class NativePositionObfuscator {

    static {
        System.loadLibrary("paramdecryptor");
    }

    private NativePositionObfuscator() {
        // no instances
    }

    static native String deobfuscate(String key, boolean base64EncodeOutput, String obfuscated);
}
