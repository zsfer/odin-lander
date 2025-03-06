package game

import rl "vendor:raylib"

@(export)
game_init :: proc(title: cstring) {
	// init window stuff
	rl.SetConfigFlags({.BORDERLESS_WINDOWED_MODE})
	rl.InitWindow(1600, 900, title)
	rl.SetTargetFPS(500)
	rl.SetExitKey(nil)

	init(title)
}

@(export)
game_should_close :: proc() -> bool {
	return rl.WindowShouldClose()
}

@(export)
game_update :: proc() {
	update()
	draw()
}

@(export)
game_shutdown :: proc() {
	shutdown()
}
