package com.vnegar.digimaze_pdf_reader_launcher.services;

import com.vnegar.digimaze_pdf_reader_launcher.models.PDFParams;

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
            result.setX1(obj.getString("x1"));
            result.setX2(obj.getString("x2"));
            result.setX3(obj.optString("x3", null));
            result.setX4(obj.optString("x4", null));

            return result;

        } catch (JSONException err) {
            System.err.println("open-file error: " + err.getMessage());
            return null;
        }
    }
}