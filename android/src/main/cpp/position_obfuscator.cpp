#include "position_obfuscator.h"
#include "base64.h"
#include "utf8_codepoints.h"

#include "mbedtls/sha256.h"
#include <cstdint>
#include <vector>
#include <cstring>

namespace positionobfuscator {

namespace {

uint32_t seedFromKeyAndLength(const std::string& key, int32_t length) {
    unsigned char hash[32];
    // mbedtls_sha256(input, ilen, output, is224=0)
    mbedtls_sha256(reinterpret_cast<const unsigned char*>(key.data()), key.size(), hash, 0);

    uint32_t seed = (static_cast<uint32_t>(hash[0]) << 24)
                   | (static_cast<uint32_t>(hash[1]) << 16)
                   | (static_cast<uint32_t>(hash[2]) << 8)
                   |  static_cast<uint32_t>(hash[3]);

    uint32_t lengthU = static_cast<uint32_t>(length);
    seed ^= lengthU * static_cast<uint32_t>(0x9e3779b1u);

    return seed;
}

// معادل lcgNext(int state)
uint32_t lcgNext(uint32_t state) {
    return state * 1664525u + 1013904223u;
}

// معادل permutation(int length)
std::vector<int32_t> permutation(const std::string& key, int32_t length) {
    std::vector<int32_t> perm(length);
    for (int32_t i = 0; i < length; ++i) {
        perm[i] = i;
    }
    if (length <= 1) {
        return perm;
    }

    uint32_t state = seedFromKeyAndLength(key, length);

    for (int32_t i = length - 1; i >= 1; --i) {
        state = lcgNext(state);
        uint32_t shifted = state >> 1;
        int32_t j = static_cast<int32_t>(shifted % static_cast<uint32_t>(i + 1));
        std::swap(perm[i], perm[j]);
    }

    return perm;
}

} // namespace

std::string deobfuscate(const std::string& key,
                         bool base64EncodeOutput,
                         const std::string& obfuscated) {
    if (obfuscated.empty()) {
        return obfuscated;
    }

    std::string decoded;
    if (base64EncodeOutput) {
        std::vector<uint8_t> bytes = b64::decode(obfuscated);
        decoded.assign(bytes.begin(), bytes.end());
    } else {
        decoded = obfuscated;
    }

    std::vector<uint32_t> cps = utf8::to_codepoints(decoded);
    int32_t length = static_cast<int32_t>(cps.size());

    std::vector<int32_t> perm = permutation(key, length);

    std::vector<uint32_t> original(cps.size());
    for (size_t dest = 0; dest < perm.size(); ++dest) {
        original[static_cast<size_t>(perm[dest])] = cps[dest];
    }

    return utf8::from_codepoints(original);
}

} // namespace positionobfuscator
