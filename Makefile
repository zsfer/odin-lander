OUT := build/
SRC := source/main_release
EXT := 
ifeq ($(OS),Windows_NT)
	EXT +=.exe
endif

OUTPUT := $(OUT)/game_debug$(EXT)

.PHONY: all build clean

all: build run

build: 
	@odin build $(SRC) -out:$(OUTPUT) -strict-style -vet -debug

run:
	$(OUTPUT)

clean:
	@rm -rf $(OUT_DIR)
