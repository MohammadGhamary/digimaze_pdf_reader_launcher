#pragma once
#include <string>
#include <optional>

namespace crypto {

std::optional<std::string> decryptTextWithPassword(const std::string& encrypted,
                                                     const std::string& password);

std::optional<std::string> decryptLic(const std::string& key,
                                       const std::string& encrypted);

} // namespace crypto
