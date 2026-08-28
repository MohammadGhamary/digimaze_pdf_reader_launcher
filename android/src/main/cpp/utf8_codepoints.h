#pragma once
#include <string>
#include <vector>
#include <cstdint>

namespace utf8 {

inline std::vector<uint32_t> to_codepoints(const std::string& input) {
    std::vector<uint32_t> out;
    size_t i = 0;
    size_t n = input.size();
    while (i < n) {
        uint8_t b0 = static_cast<uint8_t>(input[i]);
        uint32_t cp;
        size_t extra;

        if ((b0 & 0x80) == 0x00) {          // 0xxxxxxx
            cp = b0;
            extra = 0;
        } else if ((b0 & 0xE0) == 0xC0) {   // 110xxxxx
            cp = b0 & 0x1F;
            extra = 1;
        } else if ((b0 & 0xF0) == 0xE0) {   // 1110xxxx
            cp = b0 & 0x0F;
            extra = 2;
        } else if ((b0 & 0xF8) == 0xF0) {   // 11110xxx
            cp = b0 & 0x07;
            extra = 3;
        } else {
            i += 1;
            continue;
        }

        if (i + extra >= n + 1 && extra > 0 && i + extra >= n) {
            break;
        }

        bool valid = true;
        for (size_t k = 1; k <= extra; ++k) {
            if (i + k >= n) { valid = false; break; }
            uint8_t bk = static_cast<uint8_t>(input[i + k]);
            if ((bk & 0xC0) != 0x80) { valid = false; break; }
            cp = (cp << 6) | (bk & 0x3F);
        }

        if (!valid) {
            i += 1;
            continue;
        }

        out.push_back(cp);
        i += (extra + 1);
    }
    return out;
}

inline void append_utf8(std::string* out, uint32_t cp) {
    if (cp <= 0x7F) {
        out->push_back(static_cast<char>(cp));
    } else if (cp <= 0x7FF) {
        out->push_back(static_cast<char>(0xC0 | (cp >> 6)));
        out->push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else if (cp <= 0xFFFF) {
        out->push_back(static_cast<char>(0xE0 | (cp >> 12)));
        out->push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
        out->push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else {
        out->push_back(static_cast<char>(0xF0 | (cp >> 18)));
        out->push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
        out->push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
        out->push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    }
}

inline std::string from_codepoints(const std::vector<uint32_t>& cps) {
    std::string out;
    out.reserve(cps.size());
    for (uint32_t cp : cps) {
        append_utf8(&out, cp);
    }
    return out;
}

} // namespace utf8
