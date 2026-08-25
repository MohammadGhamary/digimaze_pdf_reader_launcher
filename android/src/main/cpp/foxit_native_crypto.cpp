#include <jni.h>
#include <string>
#include <vector>
#include <cstring>
#include <cstdint>

#include "mbedtls/pkcs5.h"
#include "mbedtls/md.h"
#include "mbedtls/aes.h"
#include "mbedtls/base64.h"

namespace {

    const char* kHardCodedSalt = "fb0dae6afae2a731bf1398759c4e6567";
    constexpr int kIterations = 100000;
    constexpr size_t kDerivedKeyLenBytes = 32;

    void secureZero(void* p, size_t n) {
        if (p) {
            volatile uint8_t* vp = static_cast<volatile uint8_t*>(p);
            while (n--) *vp++ = 0;
        }
    }

    std::string jstringToUtf8(JNIEnv* env, jstring s) {
        if (!s) return {};
        const char* chars = env->GetStringUTFChars(s, nullptr);
        std::string result(chars ? chars : "");
        if (chars) env->ReleaseStringUTFChars(s, chars);
        return result;
    }

    jstring utf8ToJstring(JNIEnv* env, const std::string& s) {
        return env->NewStringUTF(s.c_str());
    }

    bool base64UrlDecode(const std::string& in, std::vector<uint8_t>* out) {
        std::string normalized = in;
        for (char& c : normalized) {
            if (c == '-') c = '+';
            else if (c == '_') c = '/';
        }
        while (normalized.size() % 4 != 0) normalized.push_back('=');

        size_t decodedLen = 0;
        int rc = mbedtls_base64_decode(nullptr, 0, &decodedLen,
                                       reinterpret_cast<const uint8_t*>(normalized.data()),
                                       normalized.size());
        if (rc != 0 && rc != MBEDTLS_ERR_BASE64_BUFFER_TOO_SMALL) return false;

        out->resize(decodedLen);
        size_t written = 0;
        rc = mbedtls_base64_decode(out->data(), out->size(), &written,
                                   reinterpret_cast<const uint8_t*>(normalized.data()),
                                   normalized.size());
        if (rc != 0) return false;
        out->resize(written);
        return true;
    }

    bool constantTimeEqual(const uint8_t* a, const uint8_t* b, size_t len) {
        uint8_t diff = 0;
        for (size_t i = 0; i < len; i++) diff |= a[i] ^ b[i];
        return diff == 0;
    }

    std::string utf8ToHexCompat(const std::string& str, bool havePadding) {
        std::string result;
        size_t i = 0;
        static const char* hexDigits = "0123456789abcdef";
        while (i < str.size()) {
            unsigned char c0 = static_cast<unsigned char>(str[i]);
            int cpLen = 1;
            if ((c0 & 0x80) == 0x00) cpLen = 1;
            else if ((c0 & 0xE0) == 0xC0) cpLen = 2;
            else if ((c0 & 0xF0) == 0xE0) cpLen = 3;
            else if ((c0 & 0xF8) == 0xF0) cpLen = 4;
            if (i + cpLen > str.size()) cpLen = 1; // malformed input guard

            std::string hex;
            for (int k = 0; k < cpLen; k++) {
                unsigned char b = static_cast<unsigned char>(str[i + k]);
                hex.push_back(hexDigits[(b >> 4) & 0xF]);
                hex.push_back(hexDigits[b & 0xF]);
            }
            if (havePadding && hex.size() == 2) {
                hex = "00" + hex;
            }
            result += hex;
            i += cpLen;
        }
        return result;
    }

    bool pbkdf2DeriveKey(const std::string& password, const std::string& salt,
                         int iterations, size_t outLen, std::vector<uint8_t>* out) {
        const mbedtls_md_info_t* mdInfo = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
        if (!mdInfo) return false;

        mbedtls_md_context_t ctx;
        mbedtls_md_init(&ctx);
        if (mbedtls_md_setup(&ctx, mdInfo, 1) != 0) {
            mbedtls_md_free(&ctx);
            return false;
        }

        out->resize(outLen);
        int rc = mbedtls_pkcs5_pbkdf2_hmac(
                &ctx,
                reinterpret_cast<const uint8_t*>(password.data()), password.size(),
                reinterpret_cast<const uint8_t*>(salt.data()), salt.size(),
                static_cast<unsigned int>(iterations),
                static_cast<uint32_t>(outLen), out->data());

        mbedtls_md_free(&ctx);
        return rc == 0;
    }

    bool hmacSha256(const uint8_t* key, size_t keyLen, const uint8_t* data, size_t dataLen,
                    uint8_t out[32]) {
        const mbedtls_md_info_t* mdInfo = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
        if (!mdInfo) return false;
        return mbedtls_md_hmac(mdInfo, key, keyLen, data, dataLen, out) == 0;
    }

    bool aesCbcDecryptPkcs7(const uint8_t* key, size_t keyLen, const uint8_t* iv16,
                            const uint8_t* ciphertext, size_t ciphertextLen,
                            std::vector<uint8_t>* plaintext) {
        if (ciphertextLen == 0 || ciphertextLen % 16 != 0) return false;
        if (keyLen != 16 && keyLen != 24 && keyLen != 32) return false;

        mbedtls_aes_context aes;
        mbedtls_aes_init(&aes);
        if (mbedtls_aes_setkey_dec(&aes, key, static_cast<unsigned int>(keyLen * 8)) != 0) {
            mbedtls_aes_free(&aes);
            return false;
        }

        std::vector<uint8_t> ivCopy(iv16, iv16 + 16);
        plaintext->resize(ciphertextLen);
        int rc = mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_DECRYPT, ciphertextLen,
                                       ivCopy.data(), ciphertext, plaintext->data());
        mbedtls_aes_free(&aes);
        if (rc != 0) return false;

        // Strip PKCS7 padding.
        uint8_t pad = plaintext->back();
        if (pad == 0 || pad > 16 || pad > plaintext->size()) return false;
        for (size_t i = 0; i < pad; i++) {
            if ((*plaintext)[plaintext->size() - 1 - i] != pad) return false;
        }
        plaintext->resize(plaintext->size() - pad);
        return true;
    }

    std::string decryptLicImpl(const std::string& encryptionKey, const std::string& encryptedToken) {
        if (encryptionKey.size() != 32 || encryptedToken.empty()) return {};

        std::vector<uint8_t> derived;
        if (!pbkdf2DeriveKey(encryptionKey, kHardCodedSalt, kIterations, kDerivedKeyLenBytes, &derived)) {
            return {};
        }
        const uint8_t* signingKey = derived.data();       // bytes [0,16)
        const uint8_t* aesKey = derived.data() + 16;       // bytes [16,32)

        std::vector<uint8_t> outer;
        if (!base64UrlDecode(encryptedToken, &outer)) { secureZero(derived.data(), derived.size()); return {}; }
        std::string outerStr(outer.begin(), outer.end());
        std::vector<uint8_t> token;
        if (!base64UrlDecode(outerStr, &token)) { secureZero(derived.data(), derived.size()); return {}; }

        if (token.size() < 57) { secureZero(derived.data(), derived.size()); return {}; }

        const uint8_t* iv = token.data() + 9;                       // [9,25)
        const uint8_t* ciphertext = token.data() + 25;               // [25, len-32)
        size_t ciphertextLen = token.size() - 32 - 25;
        const uint8_t* hmacTag = token.data() + (token.size() - 32); // last 32 bytes

        uint8_t computedTag[32];
        if (!hmacSha256(signingKey, 16, token.data(), token.size() - 32, computedTag)) {
            secureZero(derived.data(), derived.size());
            return {};
        }
        if (!constantTimeEqual(computedTag, hmacTag, 32)) {
            secureZero(derived.data(), derived.size());
            return {};
        }

        std::vector<uint8_t> plaintext;
        bool ok = aesCbcDecryptPkcs7(aesKey, 16, iv, ciphertext, ciphertextLen, &plaintext);
        secureZero(derived.data(), derived.size());
        if (!ok) return {};

        return std::string(plaintext.begin(), plaintext.end());
    }

    std::string obfuscationDecryptImpl(const std::string& encrypted, const std::string& key, int /*bookId*/) {
        if (encrypted.empty() || key.size() < 4) return {};

        std::string keyHex = utf8ToHexCompat(key, false);
        std::string ivHex = utf8ToHexCompat(key.substr(0, 4), true);

        if (keyHex.size() != 16 && keyHex.size() != 24 && keyHex.size() != 32) {
            return {};
        }

        if (ivHex.size() != 16) {
            return {};
        }

        std::vector<uint8_t> keyBytes(keyHex.begin(), keyHex.end());
        std::vector<uint8_t> ivBytes(ivHex.begin(), ivHex.end());

        std::vector<uint8_t> raw;
        {
            size_t decodedLen = 0;
            int rc = mbedtls_base64_decode(nullptr, 0, &decodedLen,
                                           reinterpret_cast<const uint8_t*>(encrypted.data()),
                                           encrypted.size());
            if (rc != 0 && rc != MBEDTLS_ERR_BASE64_BUFFER_TOO_SMALL) return {};
            raw.resize(decodedLen);
            size_t written = 0;
            rc = mbedtls_base64_decode(raw.data(), raw.size(), &written,
                                       reinterpret_cast<const uint8_t*>(encrypted.data()),
                                       encrypted.size());
            if (rc != 0) return {};
            raw.resize(written);
        }

        std::vector<uint8_t> plaintext;
        if (!aesCbcDecryptPkcs7(keyBytes.data(), keyBytes.size(), ivBytes.data(), raw.data(), raw.size(), &plaintext)) {
            return {};
        }
        return std::string(plaintext.begin(), plaintext.end());
    }


    jstring Foxit_decryptLic(JNIEnv* env, jclass, jstring encryptionKey, jstring encryptedToken) {
        std::string key = jstringToUtf8(env, encryptionKey);
        std::string token = jstringToUtf8(env, encryptedToken);
        std::string result = decryptLicImpl(key, token);
        secureZero(&key[0], key.size());
        if (result.empty()) return nullptr;
        jstring jresult = utf8ToJstring(env, result);
        secureZero(&result[0], result.size());
        return jresult;
    }

    jstring Foxit_obfuscationDecrypt(JNIEnv* env, jclass, jstring encrypted, jstring key, jint bookId) {
        std::string encStr = jstringToUtf8(env, encrypted);
        std::string keyStr = jstringToUtf8(env, key);
        std::string result = obfuscationDecryptImpl(encStr, keyStr, bookId);
        secureZero(&keyStr[0], keyStr.size());
        if (result.empty()) return nullptr;
        return utf8ToJstring(env, result);
    }

    JNINativeMethod gMethods[] = {
            {const_cast<char*>("nativeDecryptLic"),
                    const_cast<char*>("(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;"),
                    reinterpret_cast<void*>(Foxit_decryptLic)},
            {const_cast<char*>("nativeObfuscationDecrypt"),
                    const_cast<char*>("(Ljava/lang/String;Ljava/lang/String;I)Ljava/lang/String;"),
                    reinterpret_cast<void*>(Foxit_obfuscationDecrypt)},
    };

}

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
    JNIEnv* env = nullptr;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }
    jclass clazz = env->FindClass("com/foxit/flutterfoxitpdf/NativeCrypto");
    if (!clazz) return JNI_ERR;

    if (env->RegisterNatives(clazz, gMethods, sizeof(gMethods) / sizeof(gMethods[0])) != 0) {
        return JNI_ERR;
    }
    return JNI_VERSION_1_6;
}