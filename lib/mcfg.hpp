#pragma once
#include <fstream>
#include <algorithm>
#include <vector>
#include <string>
#include <filesystem>
#include <stdexcept>

namespace mcfg {
  class config {
    std::filesystem::path path;
    std::vector<std::pair<std::string, std::vector<std::pair<std::string, std::string>>>> sections;

    static std::string strip(std::string str) {
      return str.erase(str.find_last_not_of(" \t\r\f\v") + 1).erase(0, str.find_first_not_of(" \t\r\f\v"));
    }

  public:
    // Parse the config at given path.
    // @throws `std::invalid_argument` - invalid config; see .what().
    // @throws `std::runtime_error` - failed to read the config.
    config(std::filesystem::path filepath) : path(filepath) {
      std::ifstream fin(path);
      if (!fin) throw std::runtime_error("Failed to open \"" + path.string() + '"');

      size_t lineno = 1;
      std::string current_section_name;
      std::vector<std::pair<std::string, std::string>> new_fields;

      // merge the accumulated fields into the section list
      auto merge_block = [&]() {
        if (new_fields.empty()) return;

        auto section = std::find_if(sections.begin(), sections.end(),
          [&](const auto &sec) { return sec.first == current_section_name; });

        // add fields that do not already exist in the section
        if (section != sections.end()) {
          for (auto &new_field : new_fields) {
            auto &fields = section->second;
            auto field = std::find_if(fields.begin(), fields.end(),
              [&](const auto &fp) { return fp.first == new_field.first; });
            if (field == fields.end()) fields.push_back(new_field);
            else field->second = new_field.second;
          }
        } else {
          sections.emplace_back(current_section_name, new_fields);
        }
        new_fields.clear();
        };

      for (std::string line; std::getline(fin, line); lineno++) {
        line = strip(line);

        if (line.empty() || line[0] == '#' || line[0] == ';')  continue;
        else if (line[0] == '[') {
          merge_block();  // store previous section
          size_t rsb_pos = line.find_last_of(']');
          if (rsb_pos == std::string::npos)
            throw std::invalid_argument(path.string() + ":" + std::to_string(lineno) + ": malformed section");
          current_section_name = strip(line.substr(1, rsb_pos - 1));
        } else {
          size_t equal_pos = line.find_first_of('=');
          if (equal_pos == std::string::npos || equal_pos == 0)
            throw std::invalid_argument(path.string() + ":" + std::to_string(lineno) + ": malformed field");
          std::string name = strip(line.substr(0, equal_pos));
          std::string value = strip(line.substr(equal_pos + 1));

          // Within the same block, last occurrence wins (overwrite)
          auto it = std::find_if(new_fields.begin(), new_fields.end(),
            [&](const auto &fp) { return fp.first == name; });

          if (it != new_fields.end()) it->second = value;
          else new_fields.emplace_back(name, value);
        }
      }

      merge_block(); // store the last block
    }

    // Return a read-write reference to the specified field.
    //
    // Create an empty section/field if it doesn't exist.
    // @note Use this where you'd use a `[]` operator with a normal array.
    std::string &operator()(std::string section_name, std::string field_name) {
      section_name = strip(section_name);
      field_name = strip(field_name);

      auto section = std::find_if(sections.begin(), sections.end(),
        [&](const auto &p) { return p.first == section_name; });

      if (section == sections.end()) {
        sections.push_back({section_name, {}});
        section = sections.end() - 1;
      }

      auto &fields = section->second;
      auto field = std::find_if(fields.begin(), fields.end(),
        [&](const auto &fp) { return fp.first == field_name; });
      if (field == fields.end()) {
        fields.push_back({field_name, ""});
        field = fields.end() - 1;
      }

      return field->second;
    }

    // Get a list of sections in the config (including the global "" section if it has any fields)
    std::vector<std::string> list_sections() const {
      std::vector<std::string> keys(sections.size());
      for (size_t i = 0; i < sections.size(); ++i) keys[i] = sections[i].first;
      return keys;
    }

    // Get a list of fields in a given section
    std::vector<std::string> list_fields(std::string_view section_name) const {
      auto section = std::find_if(sections.begin(), sections.end(),
        [&](const auto &p) { return p.first == section_name; });
      if (section == sections.end()) return {};

      auto fields = section->second;
      std::vector<std::string> keys(fields.size());
      for (size_t i = 0; i < fields.size(); ++i) keys[i] = fields[i].first;
      return keys;
    }

    bool has_section(std::string_view section_name) const {
      return std::find_if(sections.begin(), sections.end(),
        [&](const auto &p) { return p.first == section_name; }) != sections.end();
    }

    bool has_field(std::string_view section_name, std::string_view field_name) const {
      auto section = std::find_if(sections.begin(), sections.end(),
        [&](const auto &p) { return p.first == section_name; });
      if (section == sections.end()) return false;

      return std::find_if(section->second.begin(), section->second.end(),
        [&](const auto &fp) { return fp.first == field_name; }) != section->second.end();
    }

    // Erase a section and all its fields.
    void erase_section(std::string_view section_name) {
      auto it = std::find_if(sections.begin(), sections.end(),
        [&](const auto &p) { return p.first == section_name; });
      if (it != sections.end()) sections.erase(it);
    }

    // Erase a field.
    // If it was the only field in the section - erase the section as well.
    void erase(std::string_view section_name, std::string_view field_name) {
      auto section = std::find_if(sections.begin(), sections.end(),
        [&](const auto &p) { return p.first == section_name; });
      if (section == sections.end()) return;

      auto &fields = section->second;
      auto field = std::find_if(fields.begin(), fields.end(),
        [&](const auto &fp) { return fp.first == field_name; });
      if (field == fields.end()) return;

      fields.erase(field);
      if (fields.empty()) sections.erase(section);
    }

    // Save the current state of the config into a file.
    // Won't keep any comments.
    // @throws `std::runtime_error` - failed to open the file
    void save_as(std::filesystem::path filepath) const {
      std::ofstream fout(filepath);
      if (!fout) throw std::runtime_error("Failed to open \"" + filepath.string() + '"');

      for (const auto &section : sections) {
        if (!section.first.empty()) fout << "\n[" << section.first << "]\n";
        for (const auto &field : section.second)
          fout << field.first << " = " << field.second << '\n';
      }
    }

    // Save the config to the path it was read from. Remove any comments.
    // @throws `std::runtime_error` - failed to open the file
    void save() const { save_as(path); }
  };
}

/*
  Copyright (c) 2026 mint_tube <mmooyrs@gmail.com>

  Redistribution and use of this file, with or without modification,
  are permitted in any medium without royalty provided this notice is preserved.
  This file is offered as-is, without any form of warranty.
*/
