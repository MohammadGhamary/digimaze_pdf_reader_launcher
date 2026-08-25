package com.vnegar.digimaze_pdf_reader_launcher;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;

public class ParamDecryptor {

    public static PDFParams decryptParams(String params) {
        try {
            byte[] bytes = Base64.getDecoder().decode(params);
            String original = new String(bytes, StandardCharsets.UTF_8);

            List<String> argumentsArray = new ArrayList<>(Arrays.asList(original.split("æ")));

            String type = "book";
            if (!argumentsArray.isEmpty()) {
                type = argumentsArray.remove(argumentsArray.size() - 1);
            }

            boolean isSample = "sample".equalsIgnoreCase(type);

            String bookId = argumentsArray.get(3);
            ObfuscationUtil.decrypt(bookCategory, bookTitle, bookId);

            String licEncKey = decryptService.decrypt(argumentsArray.get(isSample ? 3 : 6));
            String sdkSnEnc = decryptService.decrypt(argumentsArray.get(isSample ? 11 : 14));
            String sdkKeyEnc = decryptService.decrypt(argumentsArray.get(isSample ? 5 : 8));

            String tempLic = decryptService.decryptLic(licEncKey, sdkSnEnc);
            String licSn = decryptService.decryptLic(licEncKey, tempLic);

            String licKey = decryptService.decryptLic(licEncKey, sdkKeyEnc);

            switch (type) {
                case "book": {
                    String appVersion = argumentsArray.get(0);
                    String logApiUrl = argumentsArray.get(1);
                    String deviceUID = argumentsArray.get(2);

                    String title = argumentsArray.get(4);
                    String authToken = argumentsArray.get(5);

                    String pathAndPass = decryptService.decrypt(argumentsArray.get(7));

                    String path = pathAndPass.contains("***")
                            ? pathAndPass.split("\\*\\*\\*")[0]
                            : pathAndPass;

                    // فراخوانی‌های ساختگی در کد اصلی برای فریب
                    String pass1 = decryptService.decrypt(argumentsArray.get(9));
                    String pass2 = decryptService.decrypt(argumentsArray.get(10));
                    String pass3 = decryptService.decrypt(argumentsArray.get(13));
                    String pass4 = decryptService.decrypt(argumentsArray.get(15));

                    String password = decryptService.decrypt(argumentsArray.get(11));
                    String key = decryptService.decrypt(argumentsArray.get(12));

                    String realPassword = decryptService.deobfuscate(key, password);

                    return new PDFParams(
                            deviceUID,
                            authToken,
                            logApiUrl,
                            appVersion,
                            bookId,
                            false,
                            "book",
                            path,
                            title,
                            realPassword,
                            licSn,
                            licKey
                    );
                }

                case "sample": {
                    String bookId = argumentsArray.get(0);
                    String title = argumentsArray.get(1);
                    String filePath = decryptService.decrypt(argumentsArray.get(2));

                    return new PDFParams(
                            bookId,
                            false,
                            "sample",
                            filePath,
                            title,
                            licSn,
                            licKey
                    );
                }

                default:
                    System.err.println("خطا در تعیین نوع کتاب");
                    return null;
            }

        } catch (Exception err) {
            System.err.println("open-file error: " + err.getMessage());
            // در جاوا می‌توانید مستقیماً استثنا بفرستید یا مکانیزم نمایش UI خودتان را فراخوانی کنید
            return null;
        }
    }
}
