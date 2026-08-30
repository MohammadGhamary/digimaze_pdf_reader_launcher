#include "param_decryptor.h"
#include "crypto_provider.h"
#include "base64.h"

#include <android/log.h>
#include <vector>
#include <string>

#define LOG_TAG "ParamDecryptorNative"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace paramdecryptor {

namespace {

const std::string kDelimiterAe = "\xC3\xA6";

std::vector<std::string> splitByDelimiter(const std::string& input, const std::string& delim) {
    std::vector<std::string> parts;
    size_t start = 0;
    size_t pos;
    while ((pos = input.find(delim, start)) != std::string::npos) {
        parts.push_back(input.substr(start, pos - start));
        start = pos + delim.size();
    }
    parts.push_back(input.substr(start));
    return parts;
}

std::string popLast(std::vector<std::string>& vec, const std::string& defaultValue = "") {
    if (vec.empty()) return defaultValue;
    std::string last = vec.back();
    vec.pop_back();
    return last;
}

bool safeGet(const std::vector<std::string>& vec, size_t index, std::string* out) {
    if (index >= vec.size()) return false;
    *out = vec[index];
    return true;
}

} // namespace

std::optional<PDFParamsNative> decryptClassicPdfReaderParams(const std::string& params) {
    try {
        std::string encryptedParams = b64::decode_to_string(params);
        if (encryptedParams.size() < 14 + 44) {
            LOGE("decryptClassicPdfReaderParams: payload too short after base64 decode");
            return std::nullopt;
        }

        std::string outerEncKey = encryptedParams.substr(14, 44);
        encryptedParams = encryptedParams.substr(0, 14) + encryptedParams.substr(14 + 44);

        auto originalOpt = crypto::decryptTextWithPassword(encryptedParams, outerEncKey);
        if (!originalOpt.has_value()) {
            LOGE("decryptClassicPdfReaderParams: outer layer decryption failed");
            return std::nullopt;
        }
        std::string original = *originalOpt;

        std::vector<std::string> argumentsArray = splitByDelimiter(original, kDelimiterAe);

        std::string type = popLast(argumentsArray, "book");
        bool isSample = (type == "sample");
        (void)isSample;

        // Pop innerEncKey
        std::string innerEncKey = popLast(argumentsArray, "");

        std::string arg3, arg4, arg10;
        if (!safeGet(argumentsArray, 3, &arg3) ||
            !safeGet(argumentsArray, 4, &arg4) ||
            !safeGet(argumentsArray, 10, &arg10)) {
            LOGE("decryptClassicPdfReaderParams: arguments array too short");
            return std::nullopt;
        }

        auto licEncKeyOpt = crypto::decryptTextWithPassword(arg3, innerEncKey);
        auto sdkSnEncOpt  = crypto::decryptTextWithPassword(arg10, innerEncKey);
        auto sdkKeyEncOpt = crypto::decryptTextWithPassword(arg4, innerEncKey);

        if (!licEncKeyOpt.has_value() || !sdkSnEncOpt.has_value() || !sdkKeyEncOpt.has_value()) {
            LOGE("decryptClassicPdfReaderParams: license intermediate key decryption failed");
            return std::nullopt;
        }
        std::string licEncKey = *licEncKeyOpt;

        auto snStep1 = crypto::decryptLic(licEncKey, *sdkSnEncOpt);
        if (!snStep1.has_value()) {
            LOGE("decryptClassicPdfReaderParams: x1 step1 decryption failed");
            return std::nullopt;
        }
        auto snStep2 = crypto::decryptLic(licEncKey, *snStep1);
        auto keyStep1 = crypto::decryptLic(licEncKey, *sdkKeyEncOpt);
        if (!snStep2.has_value() || !keyStep1.has_value()) {
            LOGE("decryptClassicPdfReaderParams: x1/x2 final decryption failed");
            return std::nullopt;
        }

        PDFParamsNative result;
        result.x1 = *snStep2;
        result.x2 = *keyStep1;

        if (type == "book") {
            std::string arg0, arg1, arg2, arg5, arg6, arg7, arg8, arg9, arg11;
            if (!safeGet(argumentsArray, 0, &arg0) || !safeGet(argumentsArray, 1, &arg1) ||
                !safeGet(argumentsArray, 2, &arg2) || !safeGet(argumentsArray, 5, &arg5) ||
                !safeGet(argumentsArray, 6, &arg6) || !safeGet(argumentsArray, 7, &arg7) ||
                !safeGet(argumentsArray, 8, &arg8) || !safeGet(argumentsArray, 9, &arg9) ||
                !safeGet(argumentsArray, 11, &arg11)) {
                LOGE("decryptClassicPdfReaderParams: 'book' arguments array too short");
                return std::nullopt;
            }

            result.bookId = arg0;
            result.title = arg1;

            auto pathAndPassOpt = crypto::decryptTextWithPassword(arg2, innerEncKey);
            if (!pathAndPassOpt.has_value()) {
                LOGE("decryptClassicPdfReaderParams: filePath decryption failed");
                return std::nullopt;
            }
            std::string pathAndPass = *pathAndPassOpt;
            size_t sep = pathAndPass.find("***");
            result.filePath = (sep != std::string::npos) ? pathAndPass.substr(0, sep) : pathAndPass;

            crypto::decryptTextWithPassword(arg5, innerEncKey);
            crypto::decryptTextWithPassword(arg6, innerEncKey);
            crypto::decryptTextWithPassword(arg9, innerEncKey);
            crypto::decryptTextWithPassword(arg11, innerEncKey);

            auto passwordOpt = crypto::decryptTextWithPassword(arg7, innerEncKey);
            auto obfKeyOpt = crypto::decryptTextWithPassword(arg8, innerEncKey);
            if (!passwordOpt.has_value() || !obfKeyOpt.has_value()) {
                LOGE("decryptClassicPdfReaderParams: x3/x4 decryption failed");
                return std::nullopt;
            }
            result.x3 = *passwordOpt;
            result.x4 = *obfKeyOpt;
            result.type = "book";
            return result;

        } else if (type == "sample") {
            std::string arg0, arg1, arg2;
            if (!safeGet(argumentsArray, 0, &arg0) || !safeGet(argumentsArray, 1, &arg1) ||
                !safeGet(argumentsArray, 2, &arg2)) {
                LOGE("decryptClassicPdfReaderParams: 'sample' arguments array too short");
                return std::nullopt;
            }
            auto filePathOpt = crypto::decryptTextWithPassword(arg2, innerEncKey);
            if (!filePathOpt.has_value()) {
                LOGE("decryptClassicPdfReaderParams: sample filePath decryption failed");
                return std::nullopt;
            }
            result.bookId = arg0;
            result.title = arg1;
            result.filePath = *filePathOpt;
            result.type = "sample";
            return result;

        } else {
            LOGE("decryptClassicPdfReaderParams: unknown type '%s'", type.c_str());
            return std::nullopt;
        }

    } catch (const std::exception& err) {
        LOGE("decryptClassicPdfReaderParams: exception: %s", err.what());
        return std::nullopt;
    } catch (...) {
        LOGE("decryptClassicPdfReaderParams: unknown exception");
        return std::nullopt;
    }
}

} // namespace paramdecryptor
