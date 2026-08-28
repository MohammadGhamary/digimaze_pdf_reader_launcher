package com.vnegar.digimaze_pdf_reader_launcher.services;

final class NativeParamDecryptor {

    static {
        System.loadLibrary("paramdecryptor");
    }

    private NativeParamDecryptor() {
        // no instances
    }

    static native String decryptClassicPdfReaderParams(String params);
}
