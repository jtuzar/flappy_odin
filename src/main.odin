package main

import ase "aseprite"
import "core:fmt"
import "core:log"
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
PIPE_PART_DIMENSIONS :: Vec2{96, 450}
PIPE_SPEED :: 180
TEXTURE_SCALE :: 3

main :: proc() {
	context.logger = log.create_console_logger()
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
	birdAsepriteSpriteSheet := ase.loadSpritesheet(
		"../assets/sprites/flappy.json",
		context.temp_allocator,
	)
	birdSpritesheet := new(Spritesheet)
	texturePath := fmt.tprintf("../assets/sprites/%s", birdAsepriteSpriteSheet.meta.image)
	birdSpritesheet.texture = rl.LoadTexture(
		strings.clone_to_cstring(texturePath, context.temp_allocator),
	)

	birdSpritesheet.frames = make([]Frame, len(birdAsepriteSpriteSheet.frames))

	for aseFrame, i in birdAsepriteSpriteSheet.frames {
		birdSpritesheet.frames[i] = Frame {
			rect = rl.Rectangle {
				x = aseFrame.frame.x,
				y = aseFrame.frame.y,
				width = aseFrame.frame.w,
				height = aseFrame.frame.h,
			},
			durationMs = aseFrame.duration,
		}
	}

	game^ = {
		bird = {
			position = {f32(WINDOW_WIDTH) / 6, f32(WINDOW_HEIGHT) / 2},
			radius = 27,
			velocity_y = 0,
			spritesheet = birdSpritesheet,
		},
	}
	initPipes(game.pipes[:])
}

initPipes :: proc(pipes: []Pipe) {
	pipeTexture := rl.LoadTexture("../assets/sprites/pipe.png")

	for &pipe, index in pipes {
		pipe.position.x = f32(WINDOW_WIDTH / 2 + PIPE_GAP_X * index)
		pipe.position.y = getPipePositionY()

		pipe.topPart.dimensions = PIPE_PART_DIMENSIONS
		pipe.bottomPart.dimensions = PIPE_PART_DIMENSIONS

		pipe.topPart.position.y = -PIPE_PART_OFFSET_Y
		pipe.bottomPart.position.y = PIPE_PART_OFFSET_Y

		pipe.topPart.texture = pipeTexture
		pipe.bottomPart.texture = pipeTexture
	}
}

Vec2 :: [2]f32

GameObject :: struct {
	position: Vec2,
}

Spritesheet :: struct {
	texture: rl.Texture2D,
	frames:  []Frame,
}

Frame :: struct {
	rect:       rl.Rectangle,
	durationMs: u32,
}

Pipe :: struct {
	using gameObject: GameObject,
	topPart:          PipePart,
	bottomPart:       PipePart,
}

PipePart :: struct {
	using gameObject: GameObject,
	dimensions:       Vec2,
	texture:          rl.Texture2D,
}

Bird :: struct {
	radius:           f32,
	velocity_y:       f32,
	spritesheet:      ^Spritesheet,
	using gameObject: GameObject,
}

Game :: struct {
	bird:    Bird,
	running: bool,
	pipes:   [5]Pipe,
}


simulateGame :: proc(game: ^Game) {
	if hasBirdCollided(game^) {
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
	destRect := rl.Rectangle {
		x      = bird.position.x,
		y      = bird.position.y,
		width  = bird.spritesheet.frames[0].rect.width * TEXTURE_SCALE,
		height = bird.spritesheet.frames[0].rect.height * TEXTURE_SCALE,
	}
	rl.DrawTexturePro(
		bird.spritesheet.texture,
		bird.spritesheet.frames[0].rect,
		destRect,
		{destRect.width / 2, destRect.height / 2},
		0,
		rl.WHITE,
	)
	//rl.DrawCircleLinesV(bird.position, bird.radius, rl.DARKBLUE)
}

drawPipe :: proc(pipe: Pipe) {
	topPartPosition := pipePartWorldPosition(pipe, pipe.topPart)
	bottomPartPosition := pipePartWorldPosition(pipe, pipe.bottomPart)

	destRectBottom := rl.Rectangle {
		x      = bottomPartPosition.x,
		y      = bottomPartPosition.y,
		width  = pipe.bottomPart.dimensions.x,
		height = pipe.bottomPart.dimensions.y,
	}

	rl.DrawTexturePro(
		pipe.bottomPart.texture,
		{width = f32(pipe.bottomPart.texture.width), height = f32(pipe.bottomPart.texture.height)},
		destRectBottom,
		{destRectBottom.width / 2, destRectBottom.height / 2},
		0,
		rl.WHITE,
	)

	destRectTop := rl.Rectangle {
		x      = topPartPosition.x,
		y      = topPartPosition.y,
		width  = pipe.topPart.dimensions.x,
		height = pipe.topPart.dimensions.y,
	}

	rl.DrawTexturePro(
		pipe.topPart.texture,
		{width = -f32(pipe.topPart.texture.width), height = f32(pipe.topPart.texture.height)},
		destRectTop,
		{destRectTop.width / 2, destRectTop.height / 2},
		180,
		rl.WHITE,
	)

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

hasBirdCollided :: proc(game: Game) -> bool {
	for pipe in game.pipes {
		topPartPos := pipePartWorldPosition(pipe, pipe.topPart)
		bottomPartPos := pipePartWorldPosition(pipe, pipe.bottomPart)

		if rl.CheckCollisionCircleRec(
			game.bird.position,
			game.bird.radius,
			{
				topPartPos.x - pipe.topPart.dimensions.x / 2,
				topPartPos.y - pipe.topPart.dimensions.y / 2,
				pipe.topPart.dimensions.x,
				pipe.topPart.dimensions.y,
			},
		) {
			return true
		}

		if rl.CheckCollisionCircleRec(
			game.bird.position,
			game.bird.radius,
			{
				bottomPartPos.x - pipe.bottomPart.dimensions.x / 2,
				bottomPartPos.y - pipe.bottomPart.dimensions.y / 2,
				pipe.bottomPart.dimensions.x,
				pipe.bottomPart.dimensions.y,
			},
		) {
			return true
		}
	}

	if game.bird.position.y <= game.bird.radius / 2 ||
	   game.bird.position.y >= WINDOW_HEIGHT - game.bird.radius / 2 {
		return true
	}

	return false
}

