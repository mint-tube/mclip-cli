#include <common.hpp>

[[noreturn]] void command_auth(char **argv) {
  for (int i = 0; argv[i]; ++i) log::info(argv[i]);
  exit(0);
}