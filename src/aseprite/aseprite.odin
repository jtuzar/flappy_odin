package aseprite

import "core:encoding/json"
import "core:log"
import "core:os"

Spritesheet :: struct {
	meta:   Meta,
	frames: map[string]Frame,
}

Frame :: struct {
	using asepriteSize: Size,
	w, h:               f32,
}

Size :: struct {
	x, y: f32,
}

Layer :: struct {
	name, blendMode: string,
	opacity:         u8,
}

Meta :: struct {
	app, version, image, format, scale: string,
	size:                               Size,
	frameTags:                          []string,
}

loadSpritesheet :: proc(
	path: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> ^Spritesheet {

	file, read_file_err := os.read_entire_file(path, allocator)
	if read_file_err != nil {
		log.errorf("Failed to read aseprite data file %v", read_file_err)
		return nil
	}
	defer delete(file)

	spritesheet := new(Spritesheet, allocator)

	unmarshal_err := json.unmarshal(file, spritesheet, allocator = allocator)
	if unmarshal_err != nil {
		log.errorf("Failed to unmarshal aseprite data %v", read_file_err)
		return nil
	}

	return spritesheet
}

