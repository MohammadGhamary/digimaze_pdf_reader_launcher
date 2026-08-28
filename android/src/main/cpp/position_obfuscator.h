#pragma once
#include <string>
#include <optional>

namespace positionobfuscator {

std::string deobfuscate(const std::string& key,
                         bool base64EncodeOutput,
                         const std::string& obfuscated);

} // namespace positionobfuscator
