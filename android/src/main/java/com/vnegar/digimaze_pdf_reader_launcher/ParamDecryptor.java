package com.vnegar.digimaze_pdf_reader_launcher;

import static com.vnegar.digimaze_pdf_reader_launcher.services.EncryptionService.decryptLic;
import static com.vnegar.digimaze_pdf_reader_launcher.services.EncryptionService.decryptTextWithPassword;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;

public class ParamDecryptor {

    public static PDFParams decryptParams(String params) {
        try {
            // 1. Base64 decode input
            byte[] bytes = Base64.getDecoder().decode(params);
            String encryptedParams = new String(bytes, StandardCharsets.UTF_8);

            // 2. Extract outerEncKey (14 to 58) and clean payload
            String outerEncKey = encryptedParams.substring(14, 14 + 44);
            encryptedParams = encryptedParams.substring(0, 14) + encryptedParams.substring(14 + 44);

            // 3. Decrypt outer layer
            String original = decryptTextWithPassword(encryptedParams, outerEncKey);

            // 4. Split array by boundary delimiter "æ"
            assert original != null;
            List<String> argumentsArray = new ArrayList<>(Arrays.asList(original.split("æ")));

            // Pop type (default to "book")
            String type = !argumentsArray.isEmpty() ? argumentsArray.remove(argumentsArray.size() - 1) : "book";
            boolean isSample = "sample".equals(type);

            // Pop innerEncKey
            String innerEncKey = !argumentsArray.isEmpty() ? argumentsArray.remove(argumentsArray.size() - 1) : "";

            // Decrypt license intermediate keys
            String licEncKey = decryptTextWithPassword(argumentsArray.get(isSample ? 3 : 7), innerEncKey);
            String sdkSnEnc = decryptTextWithPassword(argumentsArray.get(isSample ? 10 : 14), innerEncKey);
            String sdkKeyEnc = decryptTextWithPassword(argumentsArray.get(isSample ? 4 : 8), innerEncKey);

            // Decrypt license components
            assert licEncKey != null;
            String licSn = decryptLic(licEncKey, decryptLic(licEncKey, sdkSnEnc));
            String licKey = decryptLic(licEncKey, sdkKeyEnc);

            PDFParams result = new PDFParams();
            result.setLicSn(licSn);
            result.setLicKey(licKey);

            switch (type) {
                case "book": {
                    result.setAppVersion(argumentsArray.get(0));
                    result.setLogApiUrl(argumentsArray.get(1));
                    result.setDeviceUID(argumentsArray.get(2));
                    result.setBookId(argumentsArray.get(3));
                    result.setTitle(argumentsArray.get(4));
                    result.setUserAuthToken(argumentsArray.get(5));

                    String pathAndPass = decryptTextWithPassword(argumentsArray.get(6), innerEncKey);
                    assert pathAndPass != null;
                    result.setFilePath(pathAndPass.contains("***") ? pathAndPass.split("\\*\\*\\*")[0] : pathAndPass);

                    decryptTextWithPassword(argumentsArray.get(9), innerEncKey);
                    decryptTextWithPassword(argumentsArray.get(10), innerEncKey);
                    decryptTextWithPassword(argumentsArray.get(13), innerEncKey);
                    decryptTextWithPassword(argumentsArray.get(15), innerEncKey);

                    String password = decryptTextWithPassword(argumentsArray.get(11), innerEncKey);
                    String key = decryptTextWithPassword(argumentsArray.get(12), innerEncKey);

                    PositionObfuscator obfuscator = new PositionObfuscator(key, true);

                    result.setPassword(obfuscator.deobfuscate(password));
                    result.setType("book");
                    return result;
                }

                case "sample": {
                    result.setBookId(argumentsArray.get(0));
                    result.setTitle(argumentsArray.get(1));
                    result.setFilePath(decryptTextWithPassword(argumentsArray.get(2), innerEncKey));
                    result.setType("sample");
                    return result;
                }

                default:
                    System.err.println("خطا در تعیین نوع کتاب");
                    return null;
            }

        } catch (Exception err) {
            System.err.println("open-file error: " + err.getMessage());
            // Show alert/toast mechanism suitable for your platform (e.g., Swing, Android Toast)
            return null;
        }
    }
}