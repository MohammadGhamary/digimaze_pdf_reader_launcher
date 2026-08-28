// param_decryptor.h
// پورت شده از ParamDecryptor.java — منطق پارس و ارکستریشن رمزگشایی
// (این بخش کاملاً مشخصه و نیازی به اطلاعات اضافه نداره)

#pragma once
#include <string>
#include <optional>

namespace paramdecryptor {

struct PDFParamsNative {
    std::string type;
    std::string bookId;
    std::string title;
    std::string filePath;
    std::string licSn;
    std::string licKey;
    std::string password;
    std::string obfuscationKey;
};

std::optional<PDFParamsNative> decryptClassicPdfReaderParams(const std::string& params);

} // namespace paramdecryptor
