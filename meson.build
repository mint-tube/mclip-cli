project(
  'mclip',
  'cpp',
  version: '0.0.0',
  default_options: ['cpp_std=c++17', 'warning_level=3'],
)

if get_option('buildtype').startswith('debug')
    add_project_arguments('-DDEBUG', language: ['c', 'cpp'])
endif

if get_option('buildtype').startswith('release')
  add_project_arguments('-flto', language: ['c', 'cpp'])
  add_project_link_arguments('-flto', language: ['c', 'cpp'])
endif

executable(
  'mclip',
  sources: files('src/commands.cpp', 'src/main.cpp'),
  include_directories: include_directories('lib', 'src'),
)