package game

import "core:fmt"
import rl "vendor:raylib"


Lander :: struct {
	pos:   VEC2,
	angle: f32,
}

LANDER_SCALE :: 20
LANDER_ROT_SPEED :: 100.0

draw_lander :: proc(using l: Lander) {
	verts := [?]VEC2 {
		pos + {0, -1} * LANDER_SCALE,
		pos + {-1, -0.3} * LANDER_SCALE,
		pos + {-1, 0.3} * LANDER_SCALE,
		pos + {1, 0.3} * LANDER_SCALE,
		pos + {1, -0.3} * LANDER_SCALE,
		pos + {0, -1} * LANDER_SCALE,
	}

	thrusters := [?]VEC2 {
		pos + {-0.2, 0.3} * LANDER_SCALE,
		pos + {-0.5, 1} * LANDER_SCALE,
		pos + {0.5, 1} * LANDER_SCALE,
		pos + {0.2, 0.3} * LANDER_SCALE,
	}

	for &v in verts {
		v = v - pos
		v = rl.Vector2Rotate(v, angle * rl.DEG2RAD)
		v = v + pos
	}

	for &v in thrusters {
		v = v - pos
		v = rl.Vector2Rotate(v, angle * rl.DEG2RAD)
		v = v + pos
	}

	rl.DrawLineStrip(auto_cast &verts, 6, rl.WHITE)
	rl.DrawLineStrip(auto_cast &thrusters, 4, rl.WHITE)
	//rl.DrawRectangleV(pos, {10, 10}, rl.RED)

	rl.DrawText(fmt.caprint(pos), 10, 10, 8, rl.WHITE)
	rl.DrawText(fmt.caprint(angle), 10, 20, 12, rl.WHITE)
}

vel: VEC2
update_lander :: proc(using l: ^Lander) {
	dt := rl.GetFrameTime()

	if rl.IsKeyDown(.D) {
		angle += LANDER_ROT_SPEED * dt
	} else if rl.IsKeyDown(.A) {
		angle += -LANDER_ROT_SPEED * dt
	}

	if (rl.IsKeyDown(.L)) {
		vel.x = 1
	} else if (rl.IsKeyDown(.J)) {
		vel.x = -1
	} else {
		vel.x = 0
	}

	if (rl.IsKeyDown(.I)) {
		vel.y = -1
	} else if (rl.IsKeyDown(.K)) {
		vel.y = 1
	} else {
		vel.y = 0
	}


	pos += vel * 50 * dt
}

Game_State :: struct {
	lander: Lander,
}

gs: ^Game_State

init :: proc(title: cstring) {
	gs = new(Game_State)

	gs.lander = {
		pos   = {},
		angle = 0,
	}

	rl.EnableCursor()
}

update :: proc() {
	update_lander(&gs.lander)
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	draw_lander(gs.lander)

	rl.EndDrawing()
}

shutdown :: proc() {
	free(gs)
	rl.CloseWindow()
}
