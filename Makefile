# shmup — a 1-bit shoot-'em-up engine (core/) with three games on top, one per
# scroll frame: nova (vertical), ravine (side), skimmer (free).
#
#   make <game>          build games/<game> -> out/<Title>.pdx
#   make <game>-smoke    instrumented build (autopilot) -> out/<Title>Smoke.pdx
#   make all             every game, release builds
#   make run-<game>      build + open in the Playdate Simulator
#   make smoke           run every game's autopilot headless (tools/smoke.sh)
#   make dist            release builds, zipped into dist/
#
# A build stages core/*.lua + games/<g>/* into build/<g>/source (pdc wants one
# source root), writes smokeflag.lua, then runs pdc.
#
# smokeflag.lua carries the screenshot path, and the Makefile writes it as an
# ABSOLUTE path from $(CURDIR). It used to be a string hand-written in each
# game's main.lua, and one of the three had a stray repo prefix in it -- so that
# game's smoke screenshots silently went nowhere for its entire life. A path
# that a human types once per game is a path that is wrong in one game.
#
# It also carries SMOKE_SEED. A shipped game seeds its RNG from the clock; a
# smoke build must not, or every run is a different game and a green run proves
# nothing. `make <game>-smoke SEED=7` fixes the run; tools/smoke.sh sweeps
# several seeds and needs the bot to win ALL of them.

SDK ?= $(HOME)/Developer/PlaydateSDK
SIMULATOR ?= $(SDK)/bin/Playdate Simulator.app
GAMES := nova ravine skimmer
SEED ?= 1
OUT := out
DIST := dist

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
	printf 'SMOKE_BUILD = false\nSMOKE_SHOT_PATH = nil\n' > $$@/smokeflag.lua

build/$(1)-smoke/source: core/*.lua games/$(1)/*
	mkdir -p $$@ $(OUT) build
	cp core/*.lua $$@/
	cp -r games/$(1)/* $$@/
	cp LICENSE $$@/
	printf 'SMOKE_BUILD = true\nSMOKE_SEED = $(SEED)\nSMOKE_SHOT_PATH = "$(CURDIR)/build/$(1)-shot.png"\n' > $$@/smokeflag.lua

.PHONY: $(1) $(1)-smoke run-$(1)
endef

$(foreach g,$(GAMES),$(eval $(call GAME_RULES,$(g))))

smoke:
	tools/smoke.sh

dist: all
	mkdir -p $(DIST)
	find $(DIST) -name '*.pdx.zip' -delete
	for g in $(GAMES); do \
	  t=$$(echo $$g | awk '{print toupper(substr($$0,1,1)) substr($$0,2)}'); \
	  (cd $(OUT) && zip -qr ../$(DIST)/$$t.pdx.zip $$t.pdx); \
	done
	@ls -la $(DIST)

clean:
	rm -rf build $(OUT)

.PHONY: all clean smoke dist
