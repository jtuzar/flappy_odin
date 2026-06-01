package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
GRAVITY :: f32(1800)
FALL_GRAVITY_MULTIPLIER :: f32(1.6)
FLAP_VELOCITY :: f32(-1000)

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "flappy odin")
	game := Game {
		bird = {
			position = {f32(WINDOW_WIDTH) / 6, f32(WINDOW_HEIGHT) / 2},
			radius = 32,
			velocity_y = 0,
		},
	}

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		//update
		simulateGame(&game)

		//draw
		drawGame(&game)
		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}

Bird :: struct {
	position:   [2]f32,
	radius:     f32,
	velocity_y: f32,
}

Game :: struct {
	bird:    Bird,
	running: bool,
}

simulateGame :: proc(game: ^Game) {
	if !game.running {
		if rl.IsKeyPressed(.SPACE) {
			game.running = true
			game.bird.velocity_y = FLAP_VELOCITY
		}
		return
	}
	simulateBird(&game.bird)
}

simulateBird :: proc(bird: ^Bird) {
	if rl.IsKeyPressed(.SPACE) {
		bird.velocity_y = FLAP_VELOCITY
	}

	frameTime := rl.GetFrameTime()
	gravity := bird.velocity_y > 0 ? GRAVITY * FALL_GRAVITY_MULTIPLIER : GRAVITY
	bird.velocity_y += gravity * frameTime
	bird.position.y += bird.velocity_y * frameTime
}

drawGame :: proc(game: ^Game) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.LIGHTGRAY)

	drawFPS()
	drawBird(&game.bird)

	if !game.running {
		pauseFontSize: i32 = 72
		pauseText: cstring = "Press SPACE to start the game"
		textWidt := rl.MeasureText(pauseText, pauseFontSize)
		rl.DrawText(
			pauseText,
			i32(WINDOW_WIDTH / 2 - textWidt / 2),
			i32(WINDOW_HEIGHT / 2 - pauseFontSize / 2),
			pauseFontSize,
			rl.DARKGRAY,
		)

	}

	rl.EndDrawing()

}

drawBird :: proc(bird: ^Bird) {
	rl.DrawCircleV(bird.position, bird.radius, rl.DARKBLUE)
}

drawFPS :: proc() {
	fps := rl.GetFPS()
	fpsText := fmt.aprintf("FPS: %v", fps, allocator = context.temp_allocator)
	rl.DrawText(
		strings.clone_to_cstring(fpsText, context.temp_allocator),
		10,
		10,
		20,
		rl.DARKGREEN,
	)
}

