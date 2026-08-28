#include <jni.h>
#include <string>
#include "position_obfuscator.h"

extern "C" JNIEXPORT jstring JNICALL
Java_com_vnegar_digimaze_1pdf_1reader_1launcher_services_NativePositionObfuscator_deobfuscate(
        JNIEnv* env, jclass /* clazz */,
        jstring keyJ, jboolean base64EncodeOutputJ, jstring obfuscatedJ) {

    if (obfuscatedJ == nullptr) {
        return nullptr;
    }
    if (keyJ == nullptr) {
        return nullptr;
    }

    const char* keyChars = env->GetStringUTFChars(keyJ, nullptr);
    if (keyChars == nullptr) return nullptr;
    std::string key(keyChars);
    env->ReleaseStringUTFChars(keyJ, keyChars);

    const char* obfChars = env->GetStringUTFChars(obfuscatedJ, nullptr);
    if (obfChars == nullptr) return nullptr;
    std::string obfuscated(obfChars);
    env->ReleaseStringUTFChars(obfuscatedJ, obfChars);

    bool base64EncodeOutput = (base64EncodeOutputJ == JNI_TRUE);

    std::string result = positionobfuscator::deobfuscate(key, base64EncodeOutput, obfuscated);
    return env->NewStringUTF(result.c_str());
}
