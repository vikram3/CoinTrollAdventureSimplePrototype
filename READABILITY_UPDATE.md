# Readability update — r4

Shelters previously contained collision shapes without any visible art. They now have green outlined areas and SHELTER labels; the border brightens while occupied. Cannon emitters were invisible Node2Ds: they now draw a cannon, label and orange firing warning. Cannons wait until visible, and ranged Barreldugo enemies no longer initiate shots while off-screen. Shots already fired remain in flight.

Each level announces its name and objective for seven seconds. Pause displays the current mission, its objective and the visual legend. Exit markers have consistent arrows/rings. Collect-and-exit levels require returning to the exit with sufficient coins; merely touching it earlier no longer completes remotely.

This addresses concrete readability bugs, not a complete redesign of the 24 layouts. Campaign pacing, late-game encounter variety and chapter-specific objectives still require deeper work and human playtesting. Existing level skip controls are retained.
