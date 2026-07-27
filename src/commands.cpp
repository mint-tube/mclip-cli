#include "argparse.hpp"
#include "json.hpp"
#include "mlog.hpp"
#include "mcfg.hpp"

[[noreturn]] void create_text([[maybe_unused]] const argparse::ArgumentParser &args) {
  throw std::runtime_error("Not implemented");
}

[[noreturn]] void create_file(const argparse::ArgumentParser &args) {
  mlog::debug("Creating a file item...");
  mlog::debug("Quiet? ", args.get<bool>("-q"));
  mlog::debug("Verbose? ", args.get<bool>("-v"));
  if (auto name = args.present("-n")) mlog::debug("Name is \"", name.value(), "\"");
  else mlog::debug("No name!");
  if (auto content = args.present("-n")) mlog::debug("The file is \"", content.value(), "\"");
  else mlog::error("No content!");
  exit(0);
}