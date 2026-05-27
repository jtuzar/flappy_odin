package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

main :: proc() {
	wWidth: i32 : 1920
	wHeight: i32 : 1080
	rl.InitWindow(wWidth, wHeight, "Raylib test")

	circle := GameObject{{f32(wWidth) / 4, f32(wHeight) / 2}}

	circleRadius: f32 = 64
	circleFallSpeed: f32 = 0
	DOWN_MODIFIER: f32 : 1.6
	BASE_GRAVITY: f32 : 2200
	FLAP_UP_SPEED: f32 : -1300
	gravity := BASE_GRAVITY
	rl.SetTargetFPS(160)

	for !rl.WindowShouldClose() {
		frameTime := rl.GetFrameTime()
		//update
		if rl.IsKeyPressed(.SPACE) {
			circleFallSpeed = FLAP_UP_SPEED
		}
		gravity = circleFallSpeed > 0 ? BASE_GRAVITY * DOWN_MODIFIER : BASE_GRAVITY
		circleFallSpeed += gravity * frameTime
		circle.position.y += circleFallSpeed * frameTime

		//draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		rl.DrawCircleV(circle.position, circleRadius, rl.BLUE)

		rl.DrawFPS(10, 10)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

GameObject :: struct {
	position: [2]f32,
}

