#pragma once
#include <string>
#include <optional>

namespace paramdecryptor {

struct PDFParamsNative {
    std::string type;
    std::string bookId;
    std::string title;
    std::string filePath;
    std::string x1;
    std::string x2;
    std::string x3;
    std::string x4;
};

std::optional<PDFParamsNative> decryptClassicPdfReaderParams(const std::string& params);

} // namespace paramdecryptor
