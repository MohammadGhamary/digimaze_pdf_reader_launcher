#pragma once
#include <string>
#include <vector>
#include <cstdint>

namespace b64 {

namespace detail {

inline std::vector<uint8_t> decode_with_table(const std::string& input, const int8_t* table) {
    std::vector<uint8_t> out;
    out.reserve((input.size() / 4) * 3);

    int val = 0, bits = -8;
    for (unsigned char c : input) {
        if (c == '=' || c == '\n' || c == '\r') continue;
        int8_t d = table[c];
        if (d == -1) continue;
        val = (val << 6) + d;
        bits += 6;
        if (bits >= 0) {
            out.push_back(static_cast<uint8_t>((val >> bits) & 0xFF));
            bits -= 8;
        }
    }
    return out;
}

inline const int8_t* standardTable() {
    static int8_t table[256];
    static bool initialized = false;
    if (!initialized) {
        for (int i = 0; i < 256; ++i) table[i] = -1;
        const std::string chars =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            "abcdefghijklmnopqrstuvwxyz"
            "0123456789+/";
        for (size_t i = 0; i < chars.size(); ++i) {
            table[static_cast<uint8_t>(chars[i])] = static_cast<int8_t>(i);
        }
        initialized = true;
    }
    return table;
}

inline const int8_t* urlSafeTable() {
    static int8_t table[256];
    static bool initialized = false;
    if (!initialized) {
        for (int i = 0; i < 256; ++i) table[i] = -1;
        const std::string chars =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            "abcdefghijklmnopqrstuvwxyz"
            "0123456789-_";
        for (size_t i = 0; i < chars.size(); ++i) {
            table[static_cast<uint8_t>(chars[i])] = static_cast<int8_t>(i);
        }
        initialized = true;
    }
    return table;
}

} // namespace detail

inline std::vector<uint8_t> decode(const std::string& input) {
    return detail::decode_with_table(input, detail::standardTable());
}

inline std::string decode_to_string(const std::string& input) {
    std::vector<uint8_t> bytes = decode(input);
    return std::string(bytes.begin(), bytes.end());
}

inline std::vector<uint8_t> decode_urlsafe(const std::string& input) {
    return detail::decode_with_table(input, detail::urlSafeTable());
}

inline std::vector<uint8_t> decode_urlsafe(const std::vector<uint8_t>& input) {
    std::string asStr(input.begin(), input.end());
    return decode_urlsafe(asStr);
}

}
