#include "argparse.hpp"
#include "mcfg.hpp"
#include "mlog.hpp"

#include "commands.hpp"

void add_common(argparse::ArgumentParser &parser) {
  parser.add_argument("-v", "--verbose")
    .help("Enable verbose Logging")
    .flag();
  parser.add_argument("-q", "--quiet")
    .help("Don't write anything to the standard output")
    .flag();
  parser.add_argument("-c", "--config")
    .help("Specify the config file to use")
    .metavar("PATH");
}

int main(int argc, char **argv) {
  mlog::timestamps = false;
#ifdef DEBUG
  mlog::level = mlog::Level::Debug;
#endif

  argparse::ArgumentParser program("mclip", "indev", argparse::default_arguments::all);

  argparse::ArgumentParser sub_text("text", "", argparse::default_arguments::help);
  sub_text.add_description("Create a text item and print it's ID");
  sub_text.add_argument("content")
    .help("Text to store. '_' to read from stdin");
  sub_text.add_argument("-n", "--name")
    .help("Name of the item. Empty by default")
    .metavar("NAME");
  add_common(sub_text);
  program.add_subparser(sub_text);

  argparse::ArgumentParser sub_file("file", "", argparse::default_arguments::help);
  sub_file.add_description("Create a file item and print it's ID");
  sub_file.add_argument("source")
    .help("Path to the file. '-' to read from stdin");
  sub_file.add_argument("-n", "--name")
    .help("Name of the item. Defaults to the name of the source")
    .metavar("NAME");
  add_common(sub_file);
  program.add_subparser(sub_file);

  program.add_epilog("Type `mclip <subcommand> --help` to see command-specific parameters.");

  try {
    program.parse_args(argc, argv);
  } catch (std::exception err) {
    mlog::fatal(err.what());
    exit(1);
  }
  if (program.is_subcommand_used(sub_text))  create_text(sub_text);
  if (program.is_subcommand_used(sub_file))  create_file(sub_file);
  mlog::fatal("Need a command. Type `mclip --help` for help.");
  exit(1);
}