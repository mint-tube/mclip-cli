CXX     ?= clang++
CXXFLAGS = -std=c++17 -Wall -Wextra -Wpedantic -Werror -Ilib -Isrc
TARGET   = mclip

SRCS    := $(wildcard src/*.cpp)
OBJS    := $(SRCS:src/%.cpp=.build/%.o)
DEPS    := $(OBJS:.o=.d)
$(shell mkdir -p .build)

debug: CXXFLAGS += -ggdb3 -fsanitize=address,undefined -DDEBUG
debug: $(TARGET)

release: CXXFLAGS += -O3 -flto -DNDEBUG
release: $(TARGET)

# Link target
$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) $^ -o $@

# Compile sources
.build/%.o: src/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -MMD -MP -c $< -o $@

clean:
	rm -rf .build $(TARGET)

-include $(DEPS)
.SILENT:
.PHONY: debug release clean