#include "PathUtil.h"
#include <nlohmann/json.hpp>
#include <cassert>
#include <iostream>
#include <string>
int main()
{
    const std::string expected = "dir/\xc3\xa9-\xe6\xbc\xa2-\xf0\x9f\x98\x80.mov";
    const auto path = std::filesystem::u8path(expected);
    const auto bytes = tl::play::pathToUtf8(path);
    assert(bytes == expected);
    assert(std::filesystem::u8path(bytes) == path);
    assert(tl::play::pathToUtf8(path.filename()) == expected.substr(4));
    assert(tl::play::pathToUtf8(std::filesystem::path()).empty());
    nlohmann::json recent = nlohmann::json::array();
    recent.push_back(bytes);
    assert(recent[0].is_string());
    assert(recent[0].get<std::string>() == expected);
    assert(nlohmann::json::parse(recent.dump())[0].get<std::string>() == expected);
#ifdef __cpp_char8_t
    nlohmann::json legacy = nlohmann::json::array();
    legacy.push_back(path.u8string());
    assert(legacy[0].is_array() && !legacy[0].is_string());
#endif
#ifdef _WIN32
    const std::filesystem::path native(L"dir/\u00e9-\u6f22-\U0001f600.mov");
    assert(tl::play::pathToUtf8(native) == expected);
#endif
    std::cout << "PASS: pointer_bits=" << sizeof(void*)*8 << " cplusplus=" << __cplusplus
              << " UTF-8 round-trip/menu/JSON/empty exact; legacy char8_t control checked\n";
}
