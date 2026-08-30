#include "crypto_provider.h"
#include "base64.h"

#include <android/log.h>
#include <cstring>
#include <vector>

#include "mbedtls/aes.h"
#include "mbedtls/md.h"

#define LOG_TAG "ParamDecryptorNative"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace crypto {

namespace {

bool hmacSha256(const std::vector<uint8_t>& key,
                 const uint8_t* input, size_t inputLen,
                 uint8_t out32[32]) {
    const mbedtls_md_info_t* mdInfo = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
    if (mdInfo == nullptr) return false;
    int rc = mbedtls_md_hmac(mdInfo, key.data(), key.size(), input, inputLen, out32);
    return rc == 0;
}

bool pbkdf2HmacSha256(const std::string& password,
                       const std::string& salt,
                       uint32_t iterations,
                       uint32_t dkLen,
                       std::vector<uint8_t>* out) {
    out->assign(dkLen, 0);

    std::vector<uint8_t> pw(password.begin(), password.end());
    const uint32_t hLen = 32; // SHA-256 output
    uint32_t numBlocks = (dkLen + hLen - 1) / hLen;

    for (uint32_t blockIndex = 1; blockIndex <= numBlocks; ++blockIndex) {
        // U1 = HMAC(x3, salt || INT32_BE(blockIndex))
        std::vector<uint8_t> saltPlusIndex(salt.begin(), salt.end());
        saltPlusIndex.push_back(static_cast<uint8_t>((blockIndex >> 24) & 0xFF));
        saltPlusIndex.push_back(static_cast<uint8_t>((blockIndex >> 16) & 0xFF));
        saltPlusIndex.push_back(static_cast<uint8_t>((blockIndex >> 8) & 0xFF));
        saltPlusIndex.push_back(static_cast<uint8_t>(blockIndex & 0xFF));

        uint8_t u[32];
        if (!hmacSha256(pw, saltPlusIndex.data(), saltPlusIndex.size(), u)) {
            return false;
        }

        uint8_t t[32];
        std::memcpy(t, u, 32);

        for (uint32_t iter = 2; iter <= iterations; ++iter) {
            uint8_t uNext[32];
            if (!hmacSha256(pw, u, 32, uNext)) {
                return false;
            }
            for (int i = 0; i < 32; ++i) {
                t[i] ^= uNext[i];
            }
            std::memcpy(u, uNext, 32);
        }

        size_t offset = (blockIndex - 1) * hLen;
        size_t copyLen = std::min<size_t>(hLen, dkLen - offset);
        std::memcpy(out->data() + offset, t, copyLen);
    }

    return true;
}

bool stripPkcs7Padding(std::vector<uint8_t>* buf) {
    if (buf->empty()) return false;
    uint8_t padLen = buf->back();
    if (padLen == 0 || padLen > 16 || padLen > buf->size()) return false;
    for (size_t i = buf->size() - padLen; i < buf->size(); ++i) {
        if ((*buf)[i] != padLen) return false;
    }
    buf->resize(buf->size() - padLen);
    return true;
}

bool aesCbcDecrypt(const uint8_t* key, size_t keyLen,
                    const uint8_t* iv16,
                    const uint8_t* ciphertext, size_t ciphertextLen,
                    std::vector<uint8_t>* plaintextOut) {
    if (ciphertextLen == 0 || (ciphertextLen % 16) != 0) {
        return false;
    }

    mbedtls_aes_context ctx;
    mbedtls_aes_init(&ctx);

    if (mbedtls_aes_setkey_dec(&ctx, key, static_cast<unsigned int>(keyLen) * 8) != 0) {
        mbedtls_aes_free(&ctx);
        return false;
    }

    std::vector<uint8_t> ivCopy(iv16, iv16 + 16); // mbedtls این بافر رو in-place تغییر میده
    std::vector<uint8_t> out(ciphertextLen);

    int rc = mbedtls_aes_crypt_cbc(&ctx, MBEDTLS_AES_DECRYPT,
                                    ciphertextLen,
                                    ivCopy.data(),
                                    ciphertext,
                                    out.data());
    mbedtls_aes_free(&ctx);

    if (rc != 0) return false;

    if (!stripPkcs7Padding(&out)) return false;

    *plaintextOut = std::move(out);
    return true;
}

} // namespace


std::optional<std::string> decryptTextWithPassword(const std::string& encrypted,
                                                     const std::string& password) {
    std::vector<uint8_t> keyBytes = b64::decode(password);
    if (keyBytes.size() != 32) {
        return std::nullopt;
    }

    std::vector<uint8_t> encryptedData = b64::decode(encrypted);
    if (encryptedData.size() < 16) {
        return std::nullopt;
    }

    const uint8_t* iv = encryptedData.data();
    const uint8_t* ciphertext = encryptedData.data() + 16;
    size_t ciphertextLen = encryptedData.size() - 16;

    std::vector<uint8_t> plaintext;
    if (!aesCbcDecrypt(keyBytes.data(), keyBytes.size(), iv, ciphertext, ciphertextLen, &plaintext)) {
        return std::nullopt;
    }

    return std::string(plaintext.begin(), plaintext.end());
}

std::optional<std::string> decryptLic(const std::string& key,
                                       const std::string& encrypted) {
    if (key.size() != 32) {
        LOGE("decryptLic: encryption key must be exactly 32 characters");
        return std::nullopt;
    }

    static const std::string kHardCodedSalt = "fb0dae6afae2a731bf1398759c4e6567";
    static const uint32_t kIterations = 100000;

    std::vector<uint8_t> derivedKey;
    if (!pbkdf2HmacSha256(key, kHardCodedSalt, kIterations, 32, &derivedKey)) {
        LOGE("decryptLic: PBKDF2 key derivation failed");
        return std::nullopt;
    }

    std::vector<uint8_t> signingKey(derivedKey.begin(), derivedKey.begin() + 16);
    std::vector<uint8_t> encKey(derivedKey.begin() + 16, derivedKey.begin() + 32);

    // decode دوبل base64-url: اول متن ورودی، بعد نتیجه‌ی اون (که خودش متن base64 هست)
    std::vector<uint8_t> decodedOuter = b64::decode_urlsafe(encrypted);
    std::vector<uint8_t> token = b64::decode_urlsafe(decodedOuter);

    if (token.size() < 57) {
        LOGE("decryptLic: invalid token length");
        return std::nullopt;
    }

    const uint8_t* iv = token.data() + 9;

    size_t ciphertextLen = token.size() - 32 - 25;
    const uint8_t* ciphertext = token.data() + 25;

    const uint8_t* hmacTag = token.data() + (token.size() - 32);

    uint8_t computedTag[32];
    if (!hmacSha256(signingKey, token.data(), token.size() - 32, computedTag)) {
        LOGE("decryptLic: HMAC computation failed");
        return std::nullopt;
    }

    uint8_t diff = 0;
    for (int i = 0; i < 32; ++i) {
        diff |= static_cast<uint8_t>(computedTag[i] ^ hmacTag[i]);
    }
    if (diff != 0) {
        LOGE("decryptLic: HMAC verification failed");
        return std::nullopt;
    }

    std::vector<uint8_t> plaintext;
    if (!aesCbcDecrypt(encKey.data(), encKey.size(), iv, ciphertext, ciphertextLen, &plaintext)) {
        LOGE("decryptLic: AES decryption failed");
        return std::nullopt;
    }

    return std::string(plaintext.begin(), plaintext.end());
}

} // namespace crypto
