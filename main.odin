package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

main :: proc() {
	wWidth: i32 : 1920
	wHeight: i32 : 1080
	rl.InitWindow(wWidth, wHeight, "Raylib test")

	circle := GameObject{{f32(wWidth) / 2, f32(wHeight) / 2}}

	circleRadius: f32 = 64
	circleSpeed: f32 = 100
	rl.SetTargetFPS(160)

	for !rl.WindowShouldClose() {
		//update
		circleMoveAmount := rl.GetFrameTime() * circleSpeed
		translate2D(&circle, circleMoveAmount)


		//draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		rl.DrawCircleV(circle.position, circleRadius, rl.BLUE)

		rl.DrawFPS(10, 10)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

Direction :: enum {
	NoDirection,
	Up,
	Down,
	Left,
	Right,
}

GameObject :: struct {
	position: [2]f32,
}

translate2D :: proc(obj: ^GameObject, amount: f32) {
	if rl.IsKeyDown(.UP) {
		obj.position.y -= amount
	}
	if rl.IsKeyDown(.DOWN) {
		obj.position.y += amount
	}
	if rl.IsKeyDown(.LEFT) {
		obj.position.x -= amount
	}
	if rl.IsKeyDown(.RIGHT) {
		obj.position.x += amount
	}

}

