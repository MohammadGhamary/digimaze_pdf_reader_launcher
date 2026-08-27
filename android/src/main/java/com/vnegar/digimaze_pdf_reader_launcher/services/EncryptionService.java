package com.vnegar.digimaze_pdf_reader_launcher.services;

import javax.crypto.Cipher;
import javax.crypto.Mac;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import javax.crypto.SecretKeyFactory;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.util.Base64;

public final class EncryptionService {

    private static final byte[] PS_BYTES = {
            (byte) 0x2f, (byte) 0x66, (byte) 0x2c, (byte) 0x54, (byte) 0x6a, (byte) 0x5b,
            (byte) 0x7c, (byte) 0x32, (byte) 0x34, (byte) 0x49, (byte) 0x58, (byte) 0x37,
            (byte) 0x6b, (byte) 0x78, (byte) 0x4d, (byte) 0x34
    };

    public static String decryptTextWithPassword(String cipherText, String base64Password) {
        try {
            byte[] keyBytes = Base64.getDecoder().decode(base64Password);
            if (keyBytes.length != 32) {
                return null;
            }

            byte[] encryptedData = Base64.getDecoder().decode(cipherText);
            if (encryptedData.length < 16) {
                return null;
            }

            byte[] ivBytes = new byte[16];
            byte[] ciphertext = new byte[encryptedData.length - 16];
            System.arraycopy(encryptedData, 0, ivBytes, 0, 16);
            System.arraycopy(encryptedData, 16, ciphertext, 0, ciphertext.length);

            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            cipher.init(Cipher.DECRYPT_MODE,
                    new SecretKeySpec(keyBytes, "AES"),
                    new IvParameterSpec(ivBytes));

            byte[] ptBytes = cipher.doFinal(ciphertext);
            return new String(ptBytes, StandardCharsets.UTF_8);
        } catch (Exception e) {
            return null;
        }
    }

    public static String decryptTextWithDefaultPassword(String cipherText) {
        try {
            String keyStr = getPassword();

            String keyHex = utf8ToHex(keyStr, false);
            String ivHex = utf8ToHex(keyStr.substring(0, 4), true);

            byte[] keyBytes = keyHex.getBytes(StandardCharsets.UTF_8);
            byte[] ivBytes = ivHex.getBytes(StandardCharsets.UTF_8);

            byte[] encryptedData = Base64.getDecoder().decode(cipherText);

            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            cipher.init(Cipher.DECRYPT_MODE,
                    new SecretKeySpec(keyBytes, "AES"),
                    new IvParameterSpec(ivBytes));

            byte[] ptBytes = cipher.doFinal(encryptedData);
            return new String(ptBytes, StandardCharsets.UTF_8);
        } catch (Exception e) {
            return null;
        }
    }

    private static String utf8ToHex(String s, boolean havePadding) {
        StringBuilder out = new StringBuilder();
        byte[] bytes = s.getBytes(StandardCharsets.UTF_8);
        for (byte b : bytes) {
            if (havePadding) {
                out.append("00");
            }
            out.append(String.format("%02x", b));
        }
        return out.toString();
    }

    private static String getPassword() {
        byte[] bytes = new byte[PS_BYTES.length];
        for (int i = 0; i < PS_BYTES.length; i++) {
            bytes[i] = (byte) (PS_BYTES[i] ^ 8);
        }
        return new String(bytes, StandardCharsets.UTF_8);
    }

    public static String decryptLic(String encryptionKey, String encryptedToken) throws GeneralSecurityException {
        if (encryptionKey.length() != 32) {
            throw new IllegalArgumentException("Encryption key must be exactly 32 characters");
        }

        final String hardCodedSalt = "fb0dae6afae2a731bf1398759c4e6567";
        final int iterations = 100_000;

        SecretKeyFactory skf = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        PBEKeySpec spec = new PBEKeySpec(
                encryptionKey.toCharArray(),
                hardCodedSalt.getBytes(StandardCharsets.UTF_8),
                iterations,
                32 * 8 // 32 bytes = 256 bits
        );
        byte[] derivedKey = skf.generateSecret(spec).getEncoded();

        byte[] signingKey = new byte[16];
        byte[] encKey = new byte[16];
        System.arraycopy(derivedKey, 0, signingKey, 0, 16);
        System.arraycopy(derivedKey, 16, encKey, 0, 16);

        byte[] decodedOuter = Base64.getUrlDecoder().decode(encryptedToken);
        byte[] token = Base64.getUrlDecoder().decode(decodedOuter);

        if (token.length < 57) {
            throw new IllegalArgumentException("Invalid token length");
        }

        byte[] iv = new byte[16];
        System.arraycopy(token, 9, iv, 0, 16);

        int ciphertextLen = token.length - 32 - 25;
        byte[] ciphertext = new byte[ciphertextLen];
        System.arraycopy(token, 25, ciphertext, 0, ciphertextLen);

        byte[] hmacTag = new byte[32];
        System.arraycopy(token, token.length - 32, hmacTag, 0, 32);

        // Verify HMAC over token[..len-32]
        byte[] macInput = new byte[token.length - 32];
        System.arraycopy(token, 0, macInput, 0, token.length - 32);

        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(signingKey, "HmacSHA256"));
        byte[] computedTag = mac.doFinal(macInput);

        if (!java.security.MessageDigest.isEqual(computedTag, hmacTag)) {
            throw new GeneralSecurityException("HMAC verification failed");
        }

        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        cipher.init(Cipher.DECRYPT_MODE,
                new SecretKeySpec(encKey, "AES"),
                new IvParameterSpec(iv));

        byte[] decrypted = cipher.doFinal(ciphertext);
        return new String(decrypted, StandardCharsets.UTF_8);
    }
}