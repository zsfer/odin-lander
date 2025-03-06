package main_release

import g ".."

main :: proc() {
	g.game_init(title = "Lunar Lander")

	for !g.game_should_close() {
		g.game_update()
	}

	g.game_shutdown()
}

@(export)
NvOptimusEnablement: u32 = 1

@(export)
AmdPowerXpressRequestHighPerformance: i32 = 1
