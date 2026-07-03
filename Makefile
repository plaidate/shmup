# shmup — a generic 1-bit vertical shoot-em-up engine (core/) with games on top.
#
#   make <game>          build games/<game> -> out/<Title>.pdx
#   make <game>-smoke    instrumented build (autopilot) -> out/<Title>Smoke.pdx
#   make all             every game, release builds
#   make run-<game>      build + open in the Playdate Simulator
#
# A build stages core/*.lua + games/<g>/* into build/<g>/source (pdc wants one
# source root), writes smokeflag.lua, then runs pdc.

SDK ?= $(HOME)/Developer/PlaydateSDK
SIMULATOR ?= $(SDK)/bin/Playdate Simulator.app
GAMES := nova ravine skimmer
OUT := out

define TITLECASE
$(shell echo $(1) | awk '{print toupper(substr($$0,1,1)) substr($$0,2)}')
endef

all: $(GAMES)

define GAME_RULES
$(1): build/$(1)/source
	pdc build/$(1)/source $(OUT)/$(call TITLECASE,$(1)).pdx

$(1)-smoke: build/$(1)-smoke/source
	pdc build/$(1)-smoke/source $(OUT)/$(call TITLECASE,$(1))Smoke.pdx

run-$(1): $(1)
	open -a "$(SIMULATOR)" $(OUT)/$(call TITLECASE,$(1)).pdx

build/$(1)/source: core/*.lua games/$(1)/*
	mkdir -p $$@ $(OUT)
	cp core/*.lua $$@/
	cp -r games/$(1)/* $$@/
	cp LICENSE $$@/
	echo 'SMOKE_BUILD = false' > $$@/smokeflag.lua

build/$(1)-smoke/source: core/*.lua games/$(1)/*
	mkdir -p $$@ $(OUT)
	cp core/*.lua $$@/
	cp -r games/$(1)/* $$@/
	cp LICENSE $$@/
	echo 'SMOKE_BUILD = true' > $$@/smokeflag.lua

.PHONY: $(1) $(1)-smoke run-$(1)
endef

$(foreach g,$(GAMES),$(eval $(call GAME_RULES,$(g))))

clean:
	rm -rf build $(OUT)

.PHONY: all clean
