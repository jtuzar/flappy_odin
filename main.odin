package main

import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
GRAVITY :: f32(1800)
FALL_GRAVITY_MULTIPLIER :: f32(1.6)
FLAP_VELOCITY :: f32(-1000)

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "flappy odin")

	bird := Bird {
		position   = {f32(WINDOW_WIDTH) / 6, f32(WINDOW_HEIGHT) / 2},
		radius     = 32,
		velocity_y = 0,
	}

	rl.SetTargetFPS(160)

	for !rl.WindowShouldClose() {
		frameTime := rl.GetFrameTime()
		//update
		if rl.IsKeyPressed(.SPACE) {
			bird.velocity_y = FLAP_VELOCITY
		}
		gravity := bird.velocity_y > 0 ? GRAVITY * FALL_GRAVITY_MULTIPLIER : GRAVITY
		bird.velocity_y += gravity * frameTime
		bird.position.y += bird.velocity_y * frameTime

		//draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		rl.DrawCircleV(bird.position, bird.radius, rl.BLUE)

		rl.DrawFPS(10, 10)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

Bird :: struct {
	position:   [2]f32,
	radius:     f32,
	velocity_y: f32,
}

