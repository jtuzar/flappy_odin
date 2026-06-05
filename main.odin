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
PIPE_GAP_Y :: 260
PIPE_PART_OFFSET_Y :: PIPE_PART_DIMENSIONS.y / 2 + PIPE_GAP_Y / 2
PIPE_PART_DIMENSIONS :: Vec2{100, 500}
PIPE_SPEED :: 120

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
	initPipes(game.pipes[:])
}

initPipes :: proc(pipes: []Pipe) {
	for &pipe, index in pipes {
		pipe.position.x = f32(WINDOW_WIDTH / 2 + PIPE_GAP_X * index)
		pipe.position.y = getPipePositionY()

		pipe.topPart.dimensions = PIPE_PART_DIMENSIONS
		pipe.bottomPart.dimensions = PIPE_PART_DIMENSIONS

		pipe.topPart.position.y = -PIPE_PART_OFFSET_Y
		pipe.bottomPart.position.y = PIPE_PART_OFFSET_Y
	}
}

Vec2 :: [2]f32

GameObject :: struct {
	position: Vec2,
}

Pipe :: struct {
	using gameObject: GameObject,
	topPart:          PipePart,
	bottomPart:       PipePart,
}

PipePart :: struct {
	using gameObject: GameObject,
	dimensions:       Vec2,
}

Bird :: struct {
	radius:           f32,
	velocity_y:       f32,
	using gameObject: GameObject,
}

Game :: struct {
	bird:    Bird,
	running: bool,
	pipes:   [5]Pipe,
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
	simulatePipes(game.pipes[:])
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

simulatePipes :: proc(pipes: []Pipe) {
	for &pipe, index in pipes {
		if pipe.position.x < -PIPE_PART_DIMENSIONS.x {
			pipe.position.y = getPipePositionY()
			referencePipeIndex := (index + len(pipes) - 1) % len(pipes)
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

drawPipe :: proc(pipe: Pipe) {
	topPartPosition := pipePartWorldPosition(pipe, pipe.topPart)
	bottomPartPosition := pipePartWorldPosition(pipe, pipe.bottomPart)

	rl.DrawRectangleV(
		bottomPartPosition - pipe.bottomPart.dimensions / 2,
		pipe.bottomPart.dimensions,
		rl.GREEN,
	)
	rl.DrawRectangleV(
		topPartPosition - pipe.topPart.dimensions / 2,
		pipe.topPart.dimensions,
		rl.GOLD,
	)

	rl.DrawCircleV(pipe.position, 4, rl.RED)
	rl.DrawCircleV(topPartPosition, 4, rl.DARKPURPLE)
	rl.DrawCircleV(bottomPartPosition, 4, rl.DARKPURPLE)
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

pipePartWorldPosition :: proc(pipe: Pipe, pipePart: PipePart) -> Vec2 {
	return pipe.position + pipePart.position
}

