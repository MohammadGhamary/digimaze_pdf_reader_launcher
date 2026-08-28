package com.vnegar.digimaze_pdf_reader_launcher;

import org.json.JSONException;
import org.json.JSONObject;

public class ParamDecryptor {

    public static PDFParams decryptClassicPdfReaderParams(String params) {
        try {
            String json = NativeParamDecryptor.decryptClassicPdfReaderParams(params);
            if (json == null) {
                System.err.println("open-file error: native decryption returned null");
                return null;
            }

            JSONObject obj = new JSONObject(json);

            PDFParams result = new PDFParams();
            result.setType(obj.getString("type"));
            result.setBookId(obj.getString("bookId"));
            result.setTitle(obj.getString("title"));
            result.setFilePath(obj.getString("filePath"));
            result.setLicSn(obj.getString("licSn"));
            result.setLicKey(obj.getString("licKey"));
            result.setPassword(obj.optString("password", null));
            result.setObfuscationKey(obj.optString("obfuscationKey", null));

            return result;

        } catch (JSONException err) {
            System.err.println("open-file error: " + err.getMessage());
            return null;
        }
    }
}