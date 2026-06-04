package main

import "core:fmt"
import "core:math/rand"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
GRAVITY :: f32(1800)
FALL_GRAVITY_MULTIPLIER :: f32(1.6)
FLAP_VELOCITY :: f32(-800)
PIPE_GAP_X :: 400
PIPE_GAP_Y :: 250
PIPE_PART_DIMENSIONS :: [2]f32{100, 500}
PIPE_SPEED :: 120
PIPE_ARRAY_SIZE :: 5

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "flappy odin")
	game: Game
	initGame(&game)

	for !rl.WindowShouldClose() {
		//update
		simulateGame(&game)

		//draw
		drawGame(&game)
		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}

initGame :: proc(game: ^Game) {
	game^ = {
		bird = {
			position = {f32(WINDOW_WIDTH) / 6, f32(WINDOW_HEIGHT) / 2},
			radius = 32,
			velocity_y = 0,
		},
	}
	initPipes(&game.pipes)
}

initPipes :: proc(pipes: ^[PIPE_ARRAY_SIZE]GameObject) {
	for &pipe, index in pipes {
		pipe.position.x = f32(WINDOW_WIDTH / 2 + PIPE_GAP_X * index)
		pipe.position.y = getPipePositionY()
	}
}

GameObject :: struct {
	position: [2]f32,
}

Bird :: struct {
	radius:           f32,
	velocity_y:       f32,
	using gameObject: GameObject,
}

Game :: struct {
	bird:    Bird,
	running: bool,
	pipes:   [PIPE_ARRAY_SIZE]GameObject,
}


simulateGame :: proc(game: ^Game) {
	if game.bird.position.y <= game.bird.radius / 2 ||
	   game.bird.position.y >= WINDOW_HEIGHT - game.bird.radius / 2 {
		time.sleep(2 * time.Second)
		initGame(game)
	}


	if !game.running {
		if rl.IsKeyPressed(.SPACE) {
			game.running = true
			game.bird.velocity_y = FLAP_VELOCITY
		}
		return
	}


	simulateBird(&game.bird)
	simulatePipes(&game.pipes)
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

simulatePipes :: proc(pipes: ^[PIPE_ARRAY_SIZE]GameObject) {
	for &pipe, index in pipes {
		if pipe.position.x < -PIPE_PART_DIMENSIONS.x {
			pipe.position.y = getPipePositionY()
			referencePipeIndex := (index + PIPE_ARRAY_SIZE - 1) % PIPE_ARRAY_SIZE
			pipe.position.x = pipes[referencePipeIndex].position.x + PIPE_GAP_X
		}
		pipe.position.x -= rl.GetFrameTime() * PIPE_SPEED
	}
}

drawGame :: proc(game: ^Game) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.LIGHTGRAY)

	drawFPS()
	for pipe in game.pipes {
		drawPipe(pipe)
	}
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

drawPipe :: proc(pipe: GameObject) {
	rl.DrawRectangleV(
		pipe.position + {0, -PIPE_GAP_Y / 2 - PIPE_PART_DIMENSIONS.y},
		PIPE_PART_DIMENSIONS,
		rl.GREEN,
	)
	rl.DrawRectangleV(pipe.position + {0, PIPE_GAP_Y / 2}, PIPE_PART_DIMENSIONS, rl.RED)
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

getPipePositionY :: proc() -> f32 {
	return WINDOW_HEIGHT / 2 + f32(rand.int32_range(-100, 100))
}

