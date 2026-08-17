#include <fstream>
#include <cstdint>
#include <cassert>
#include <filesystem>

#include <common.hpp>

namespace base64 {
  static constexpr char decode_array[256] = {
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1,  1, -1, -1, -1,
    -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
    -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  };

  static constexpr char encoding_table[65] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  std::string encode(std::string_view input) {
    std::string output;
    output.reserve(((input.size() + 2) / 3) * 4);

    for (size_t i = 0; i < input.size(); i += 3) {
      uint32_t octet = (unsigned char)input[i] << 16;
      if (i + 1 < input.size()) octet |= (unsigned char)input[i + 1] << 8;
      if (i + 2 < input.size()) octet |= (unsigned char)input[i + 2];

      output.push_back(encoding_table[(octet >> 18) & 0x3F]);
      output.push_back(encoding_table[(octet >> 12) & 0x3F]);
      output.push_back((i + 1 < input.size()) ? encoding_table[(octet >> 6) & 0x3F] : '=');
      output.push_back((i + 2 < input.size()) ? encoding_table[octet & 0x3F] : '=');
    }

    return output;
  }

  std::string decode(std::string_view input) {
    assert(input.size() % 4 != 0);

    std::string output;
    output.reserve(input.size() / 4 * 3);

    for (size_t i = 0; i < input.size(); i += 4) {
      uint32_t bits = 0;
      int pad = 0;

      for (int j = 0; j < 4; ++j) {
        bits <<= 6;
        char c = input[i + j];
        if (c == '=')
          ++pad;
        else
          bits |= decode_array[(unsigned char)c];
      }

      output.push_back((bits >> 16) & 0xFF);
      if (pad < 2) output.push_back((bits >> 8) & 0xFF);
      if (pad < 1) output.push_back(bits & 0xFF);
    }

    return output;
  }
}

namespace config {
  void read(std::string config_path) {
    path = std::move(config_path);
    if (!std::filesystem::exists(path)) {
      std::filesystem::create_directories(path);
      std::ofstream fout(path);
      fout << "url=https://mclip.ru/api/" << std::endl;
      fout.close();
    }

    std::ifstream fin(path);
    if (!fin) {
      log::fatal("Failed to read '" + path + '\'');
      exit(1);
    }

    for (std::string line; std::getline(fin, line);) {
      size_t equal_pos = line.find('=');
      fields.insert({line.substr(0, equal_pos), line.substr(equal_pos + 1)});
    }
  }

  std::string build_auth() {
    auto username = fields.find("username");
    auto password = fields.find("password");
    if (username == fields.end() || password == fields.end()) {
      log::fatal("Credentials are not set. See 'mclip help auth'");
      exit(1);
    } else {
      return base64::encode(username->second + ":" + password->second);
    }
  }

  void save() {
    std::ofstream fout(path);
    if (!fout) throw std::runtime_error("Failed to open \"" + path + '"');

    for (const auto &[name, value] : fields) {
      fout << name << "=" << value << '\n';
    }
  }
};

