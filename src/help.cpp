#include <common.hpp>

// 
// "-v"      
// "-c PATH" Specify the config file to use

[[noreturn]] void command_help(char **argv) {
  if (!argv[0]) {
    std::cout << "Usage: mclip [-v] [-q] [-c <path>] <command> [<args>...]\n";
    std::cout << "Commands:\n";
    std::cout << "  ls     List items\n";
    std::cout << "  new    Create an item\n";
    std::cout << "  edit   Edit an existing item\n";
    std::cout << "  rm     Delete an item\n";
    std::cout << "  auth   Register, login or change password\n";
    std::cout << "  help   Get usage help\n";
    std::cout << "Flags (used before the command):\n";
    std::cout << "  -q     Suppress all warnings and error messages\n";
    std::cout << "  -v     Enable verbose logging\n";
    std::cout << "Use 'mclip help <command>' to read about a specific command\n";
  } else if (!strcmp(argv[0], "ls")) {
    std::cout << "Usage: mclip ls [<filter> <filter_arg>]\n";
    std::cout << "Filters:\n";
    std::cout << "  text         Only 'text' items\n";
    std::cout << "  file         Only 'file' items\n";
    std::cout << "  name <pref>  Search by name prefix\n";
    std::cout << "  since <date> Items that changed after UTC 00:00 of YYYY.MM.DD)\n";
    std::cout << "\n";
  } else if (!strcmp(argv[0], "new")) {
    std::cout << "Usage: mclip new text <name> <content>...\n";
    std::cout << "       mclip new file <path>\n";
    std::cout << "Put \"s around <name> if it contains spaces\n";
    std::cout << "Use '-' as text's content to read from stdin\n";
  } else if (!strcmp(argv[0], "edit")) {
    std::cout << "Usage: mclip edit <id> <field> <value>\n";
    std::cout << "Fields:\n";
    std::cout << "  name    Change file's name of text's header\n";
    std::cout << "  content Path to data for a file or text's new value\n";
    std::cout << "Use '-' as text's content to read from stdin\n";
  } else if (!strcmp(argv[0], "rm")) {
    std::cout << "Usage: mclip rm <id>\n";
    std::cout << "Deletion will fail if more than 1 item is matches the prefix\n";
  } else if (!strcmp(argv[0], "auth")) {
    std::cout << "Usage: mclip auth <subcommand>\n";
    std::cout << "Subcommands:\n";
    std::cout << "  create <username> <password>  Create an account\n";
    std::cout << "  login <username> <password>   Change credentials\n";
    std::cout << "  changepass <new_password>     Update password to current account\n";
    std::cout << "  delete                        Delete current account\n";
    std::cout << "  endpoint <url>                Change the remote server used\n";
    std::cout << "The configuration is stored at " << config::path;
    std::cout << "'https://mclip.ru/api/' is the default endpoint.\n";
  } else if (!strcmp(argv[0], "help")) {
    std::cout << "Usage: mclip help [<command>]\n";
  }

  exit(0);
}