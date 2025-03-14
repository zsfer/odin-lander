package game

import "core:fmt"
import "core:math/linalg"
import "core:math/noise"
import "core:math/rand"
import "core:slice"
import "core:strings"
import rl "vendor:raylib"

LUNAR_GRAVITY :: 1.6
LANDING_ZONES_COUNT :: 6
WORLD_POINTS :: 40

WIN_MAX_ANGLE :: 8
WIN_MAX_SPEED :: 10

KB_ROT_POS :: rl.KeyboardKey.D
KB_ROT_NEG :: rl.KeyboardKey.A
KB_THRUST :: rl.KeyboardKey.W

Lander :: struct {
	verts: [6]VEC2,
	pos:   VEC2,
	angle: f32,
	vel:   VEC2,
	fuel:  f32,
}

LANDER_SCALE :: 10
LANDER_ROT_SPEED :: 100.0

draw_lander :: proc(using l: ^Lander) {
	verts = [?]VEC2 {
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

	thrust := [?]VEC2 {
		pos + {-0.2, 1} * LANDER_SCALE,
		pos + {-0.3, 1.5} * LANDER_SCALE,
		pos + {-0.2, 4} * LANDER_SCALE,
		pos + {0.3, 1.5} * LANDER_SCALE,
		pos + {0.2, 1} * LANDER_SCALE,
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

	for &v in thrust {
		v = v - pos
		v = rl.Vector2Rotate(v, angle * rl.DEG2RAD)
		v = v + pos
	}

	rl.DrawLineStrip(auto_cast &verts, 6, rl.WHITE)
	rl.DrawLineStrip(auto_cast &thrusters, 4, rl.WHITE)
	if rl.IsKeyDown(KB_THRUST) {
		rl.DrawLineStrip(auto_cast &thrust, 5, rl.ORANGE)
	}

}

update_lander :: proc(using l: ^Lander) {
	if gs.is_landed do return
	dt := rl.GetFrameTime()

	vel.y += LUNAR_GRAVITY * dt

	if rl.IsKeyDown(KB_ROT_POS) && angle < 90 {
		angle += LANDER_ROT_SPEED * dt
	} else if rl.IsKeyDown(KB_ROT_NEG) && angle > -90 {
		angle += -LANDER_ROT_SPEED * dt
	}
	angle = linalg.clamp(f32(-90.0), f32(90.0), angle)

	if rl.IsKeyDown(KB_THRUST) {
		thrust_dir := VEC2{linalg.sin(angle * rl.DEG2RAD), -linalg.cos(angle * rl.DEG2RAD)}
		vel += thrust_dir * 10 * dt

		fuel -= 0.7 * dt
	}

	pos += vel * dt

	if pos.x > f32(rl.GetScreenWidth()) {
		pos.x = 0
	} else if (pos.x < 0) {
		pos.x = f32(rl.GetScreenWidth())
	}
}

generate_world :: proc(landing_zones: ^[dynamic]int) -> [WORLD_POINTS]VEC2 {
	points: [WORLD_POINTS]VEC2 = {}
	start_y := f32(rl.GetScreenHeight()) * 0.7
	seed := rand.int63()
	expl_scale = f32(5) * LANDER_SCALE

	for i in 0 ..< WORLD_POINTS {
		x := f32(i) * f32(rl.GetScreenWidth()) / f32(WORLD_POINTS)
		y := start_y

		n := noise.noise_2d(seed, {f64(x), f64(y)}) * 0.2
		scaled_y := y * n + start_y

		if i % (WORLD_POINTS / LANDING_ZONES_COUNT) == 0 && i != 0 {
			scaled_y = points[i - 1].y
			append(landing_zones, i)
		}

		points[i] = {x, scaled_y}
	}

	return points
}

draw_world :: proc(points: [WORLD_POINTS]VEC2) {
	p := points
	rl.DrawLineStrip(auto_cast &p, WORLD_POINTS, rl.WHITE)

	for zone_idx in gs.landing_zones {
		zone_a := gs.world[zone_idx]
		zone_b := gs.world[zone_idx - 1]

		zones: [2]VEC2 = {zone_b, zone_a}
		rl.DrawLineStrip(auto_cast &zones, 2, rl.RED)
		zone_mid := (zone_a + zone_b) / 2
		rl.DrawText(
			"LZ",
			i32(zone_mid.x) - (rl.MeasureText("LZ", 4) / 2),
			i32(zone_mid.y) + 4,
			4,
			rl.WHITE,
		)
	}
}

expl_scale := f32(5) * LANDER_SCALE
draw_explosion :: proc(using l: ^Lander) {
	dt := rl.GetFrameTime()
	rl.DrawCircleV(l.pos, expl_scale, rl.RED)

	expl_scale -= 80 * dt
}

check_collisions :: proc(l: ^Lander, world: ^[WORLD_POINTS]VEC2, lz: ^[dynamic]int) {
	for world_point, idx in world {
		if idx < WORLD_POINTS - 1 &&
		   rl.CheckCollisionCircleLine(l.pos, LANDER_SCALE, world_point, world[idx + 1]) {
			gs.is_landed = true
			// landed inside LZ
			if slice.contains(lz[:], idx + 1) &&
			   abs(l.angle) < WIN_MAX_ANGLE &&
			   rl.Vector2Length(l.vel) < WIN_MAX_SPEED {
				l.angle = 0
				l.vel = {}
				gs.win_state = .Win
				gs.game_over_text = "You landed safely!"
				break
			}

			gs.win_state = .Lose
			gs.game_over_text = "BOOM!"
		}
	}
}


draw_ui :: proc(using g: ^Game_State) {
	rl.DrawText(fmt.caprint("ROT", int(lander.angle)), 20, 20, 24, rl.WHITE)
	rl.DrawText(fmt.caprint("SPD", int(rl.Vector2Length(lander.vel))), 20, 50, 24, rl.WHITE)
	rl.DrawText(fmt.caprint("FUL", int(lander.fuel)), 20, 75, 24, rl.WHITE)

	if is_landed {
		col := win_state == .Win ? rl.GREEN : rl.RED
		text := strings.clone_to_cstring(game_over_text)
		rl.DrawText(
			text,
			(rl.GetScreenWidth() / 2) - rl.MeasureText(text, 48),
			rl.GetScreenHeight() / 2,
			48,
			col,
		)
	}
}

Win_State :: enum {
	Win,
	Lose,
}

Game_State :: struct {
	lander:         Lander,
	world:          [WORLD_POINTS]VEC2,
	landing_zones:  [dynamic]int,
	is_landed:      bool,
	win_state:      Win_State,
	game_over_text: string,
}

gs: ^Game_State

init :: proc(title: cstring) {
	gs = new(Game_State)

	restart_game(gs)
	rl.EnableCursor()
}

restart_count := 0
restart_game :: proc(gs: ^Game_State, fuel: f32 = 300) {
	growth := linalg.pow(f32(1.0) + f32(0.5), f32(restart_count))

	gs.lander = {
		pos   = {50, 50}, // START POS
		angle = -90,
		vel   = VEC2{30.0, 10.0} * growth,
		fuel  = fuel,
	}
	gs.is_landed = false
	gs.game_over_text = ""
	start_restart = false

	gs.landing_zones = {}
	gs.world = generate_world(&gs.landing_zones)

	restart_count += 1
}

start_restart := false
restart_timer := f32(5)
update :: proc() {
	if rl.IsKeyPressed(.R) {
		restart_game(gs)
	}

	update_lander(&gs.lander)
	check_collisions(&gs.lander, &gs.world, &gs.landing_zones)

	if gs.is_landed && !start_restart {
		start_restart = true
		restart_timer = 5
	}

	if start_restart {
		restart_timer -= rl.GetFrameTime()

		if restart_timer <= 0 {
			start_restart = false
			restart_game(gs, gs.lander.fuel)
		}
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	draw_world(gs.world)
	if gs.is_landed && gs.win_state == .Lose {
		draw_explosion(&gs.lander)
	} else {
		draw_lander(&gs.lander)
	}

	draw_ui(gs)


	rl.EndDrawing()
}

shutdown :: proc() {
	free(gs)
	rl.CloseWindow()
}
