#include <iostream>
#include <unordered_map>
#include <string>
#include <cstring>

namespace log {
  inline bool quiet;
  inline bool verbose;

  template<typename... Args>
  void info(Args&&... args) {
    if (quiet or !verbose) return;
    std::cerr << "\x1b[1;36mINFO:\x1b[0m ";
    ((std::cerr << std::forward<Args>(args)), ...);
    std::cerr << std::endl;
  }

  template<typename... Args>
  void warn(Args&&... args) {
    if (quiet) return;
    std::cerr << "\x1b[1;33mWARNING:\x1b[0m ";
    ((std::cerr << std::forward<Args>(args)), ...);
    std::cerr << std::endl;
  }

  template<typename... Args>
  void fatal(Args&&... args) {
    if (quiet) return;
    std::cerr << "\x1b[1;31mFATAL:\x1b[0m ";
    ((std::cerr << std::forward<Args>(args)), ...);
    std::cerr << std::endl;
  }
}

namespace base64 {
  std::string encode(std::string_view input);
  std::string decode(std::string_view input);
}

namespace config {
  inline std::string path;
  inline std::unordered_map<std::string, std::string> fields;

  void read(std::string config_path);
  std::string build_auth();
  void save();
}


