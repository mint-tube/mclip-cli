CXX = clang++
CFLAGS = -std=c++17 -Wall -Wextra -Wpedantic -Werror -MMD
TARGET = mclip

SRCS = $(shell find src -name '*.cpp')
OBJS = $(SRCS:src/%.cpp=.build/%.o)
DEPS = $(SRCS:src/%.cpp=.build/%.d)
 
$(shell mkdir -p .build)

debug: CFLAGS += -O0 -ggdb3 -DDEBUG -fsanitize=address
debug: $(TARGET)

release: CFLAGS += -O3 -flto -DNDEBUG
release: $(TARGET)

# Link target
$(TARGET): $(OBJS)
	$(CXX) $(CFLAGS) $^ -o $@
	./$(TARGET)
	rm ./$(TARGET) 2>/dev/null

# Compile sources
.build/%.o: src/%.cpp
	$(CXX) $(CFLAGS) -c $< -o $@

clean:
	rm .build/* 2>/dev/null || true

-include $(DEPS)
.SILENT:
.PHONY: debug release clean