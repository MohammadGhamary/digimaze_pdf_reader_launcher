#include <jni.h>
#include <string>
#include "param_decryptor.h"

namespace {

std::string jsonEscape(const std::string& in) {
    std::string out;
    out.reserve(in.size() + 8);
    for (char c : in) {
        switch (c) {
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n";  break;
            case '\r': out += "\\r";  break;
            case '\t': out += "\\t";  break;
            default:   out += c;      break;
        }
    }
    return out;
}

std::string toJson(const paramdecryptor::PDFParamsNative& p) {
    std::string json = "{";
    json += "\"type\":\"" + jsonEscape(p.type) + "\",";
    json += "\"bookId\":\"" + jsonEscape(p.bookId) + "\",";
    json += "\"title\":\"" + jsonEscape(p.title) + "\",";
    json += "\"filePath\":\"" + jsonEscape(p.filePath) + "\",";
    json += "\"licSn\":\"" + jsonEscape(p.licSn) + "\",";
    json += "\"licKey\":\"" + jsonEscape(p.licKey) + "\",";
    json += "\"password\":\"" + jsonEscape(p.password) + "\",";
    json += "\"obfuscationKey\":\"" + jsonEscape(p.obfuscationKey) + "\"";
    json += "}";
    return json;
}

} // namespace

extern "C" JNIEXPORT jstring JNICALL
Java_com_vnegar_digimaze_1pdf_1reader_1launcher_NativeParamDecryptor_decryptClassicPdfReaderParams(
        JNIEnv* env, jclass /* clazz */, jstring paramsJ) {

    if (paramsJ == nullptr) {
        return nullptr;
    }

    const char* paramsChars = env->GetStringUTFChars(paramsJ, nullptr);
    if (paramsChars == nullptr) {
        return nullptr;
    }
    std::string params(paramsChars);
    env->ReleaseStringUTFChars(paramsJ, paramsChars);

    auto resultOpt = paramdecryptor::decryptClassicPdfReaderParams(params);
    if (!resultOpt.has_value()) {
        return nullptr;
    }

    std::string json = toJson(*resultOpt);
    return env->NewStringUTF(json.c_str());
}
