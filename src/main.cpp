#include <common.hpp>

[[noreturn]] void command_ls(char **argv);
[[noreturn]] void command_new(char **argv);
[[noreturn]] void command_edit(char **argv);
[[noreturn]] void command_rm(char **argv);
[[noreturn]] void command_auth(char **argv);
[[noreturn]] void command_help(char **argv);

int main(int argc, char **argv) {
#ifdef _WIN32
  config::read(std::string(getenv("APPDATA")) + "\\mclip\\config.ini");
#else
  config::read(std::string(getenv("HOME")) + "/.config/mclip/config.ini");
#endif

  int i = 1;

  // Parse global flags
  for (; i < argc and argv[i][0] == '-'; ++i) {
    if (!strcmp(argv[i], "-q")) log::quiet = true;
    else if (!strcmp(argv[i], "-v")) log::verbose = true;
    else {
      log::fatal("Unknown flag: '", argv[i], '\'');
      log::info("See 'mclip help'");
      return 1;
    }
  }

  // Pass the control to a command handler
  if (!argv[i]) log::fatal("Expected a command; see 'mclip help'");
  else if (!strcmp(argv[i], "ls"))   command_ls(argv + i + 1);
  else if (!strcmp(argv[i], "new"))  command_new(argv + i + 1);
  else if (!strcmp(argv[i], "edit")) command_edit(argv + i + 1);
  else if (!strcmp(argv[i], "rm"))   command_rm(argv + i + 1);
  else if (!strcmp(argv[i], "auth"))  command_auth(argv + i + 1);
  else if (!strcmp(argv[i], "help")) command_help(argv + i + 1);
  else log::fatal("Unknown command: '", argv[i], "'; see 'mclip help'");

  std::cerr << "";
  return 1;
}