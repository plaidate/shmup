#!/bin/bash
# shmup smoke runner: build the instrumented variant, run its autopilot in the
# Playdate Simulator, poll the datastore, report.
#
#   tools/smoke.sh <game> [seconds] [seed]   one game, one seed
#   tools/smoke.sh                           all three x every seed in SEEDS
#
# Two bars, both deliberately high.
#
# 1. A run is green only when the bot reached the WIN screen ("wins":1). A bot
#    that survives without winning has quietly stopped testing the second half
#    of the game.
#
# 2. Runs are SEEDED, and the bot must win every seed. A smoke build that seeds
#    from the clock plays a different game every time: a pass proves nothing and
#    a failure is indistinguishable from bad luck. This engine's cave-flyer sat
#    at seven wins in eight for an afternoon, which is the worst place to be --
#    too good to look broken, too flaky to trust. Fixed seeds turn "it usually
#    works" into a list of games that either work or do not.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM="$HOME/Developer/PlaydateSDK/bin/Playdate Simulator.app/Contents/MacOS/Playdate Simulator"
SEEDS="${SEEDS:-1 2 3 4}"

run_one() {
    local GAME="$1"
    local SECS="${2:-90}"
    local SEED="${3:-1}"
    local TITLE
    TITLE="$(echo "$GAME" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
    local BUNDLE="com.sdwfrost.shmup.$GAME"
    local DATA="$HOME/Developer/PlaydateSDK/Disk/Data/$BUNDLE"
    local SHOT="$ROOT/build/$GAME-shot.png"

    cd "$ROOT"
    rm -rf "build/$GAME-smoke"
    make "$GAME-smoke" SEED="$SEED" >/dev/null || {
        echo "$GAME: BUILD FAILED"; return 1; }

    pkill -9 -f "Playdate Simulator" 2>/dev/null
    rm -rf "$DATA"
    rm -f "$SHOT" "$ROOT"/build/"$GAME"-shot-*.png
    ("$SIM" "$ROOT/out/${TITLE}Smoke.pdx" >"$ROOT/build/$GAME-sim.log" 2>&1 &)

    local ITER=$((SECS / 5))
    for _ in $(seq 1 "$ITER"); do
        [ -s "$DATA/err.json" ] && break
        grep -q '"wins":1' "$DATA/smoke.json" 2>/dev/null && break
        sleep 5
    done
    sleep 2
    pkill -9 -f "Playdate Simulator" 2>/dev/null

    echo "=== $GAME (seed $SEED)"
    if [ -s "$DATA/err.json" ]; then
        echo "  ERROR: $(cat "$DATA/err.json")"
        rm -rf "$DATA"
        return 1
    fi
    if [ ! -s "$DATA/smoke.json" ]; then
        echo "  NO HEARTBEAT (never reached the first 90-frame beat)"
        rm -rf "$DATA"
        return 1
    fi

    local JSON
    JSON="$(cat "$DATA/smoke.json")"
    echo "  $JSON"
    [ -f "$SHOT" ] && echo "  shot: $SHOT"
    mkdir -p "$ROOT/results"
    cp "$DATA/smoke.json" "$ROOT/results/$GAME.json" 2>/dev/null
    rm -rf "$DATA"

    if echo "$JSON" | grep -q '"wins":1'; then
        echo "  WON"
        return 0
    fi
    echo "  DID NOT WIN -- the bot must beat the game, not merely survive it"
    return 1
}

if [ $# -ge 1 ]; then
    run_one "$@"
    exit $?
fi

fail=0
for g in nova ravine skimmer; do
    for s in $SEEDS; do
        run_one "$g" 150 "$s" || fail=1
    done
done
echo
if [ $fail -eq 0 ]; then
    echo "SMOKE: every game won on every seed ($SEEDS)"
else
    echo "SMOKE: FAILED"
fi
exit $fail
