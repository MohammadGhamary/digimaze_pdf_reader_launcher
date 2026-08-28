package com.vnegar.digimaze_pdf_reader_launcher.services;
public class PositionObfuscator {

    private final String key;
    private final boolean base64EncodeOutput;

    public PositionObfuscator(String key, boolean base64EncodeOutput) {
        this.key = key;
        this.base64EncodeOutput = base64EncodeOutput;
    }

    public String deobfuscate(String obfuscated) {
        if (obfuscated == null || obfuscated.isEmpty()) {
            return obfuscated;
        }
        return NativePositionObfuscator.deobfuscate(key, base64EncodeOutput, obfuscated);
    }
}