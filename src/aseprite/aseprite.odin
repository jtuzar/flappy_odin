package aseprite

import "core:encoding/json"
import "core:log"
import "core:os"

Spritesheet :: struct {
	meta:   Meta,
	frames: []FrameEntry,
}

FrameEntry :: struct {
	frame:    Frame,
	duration: u32,
}

Frame :: struct {
	x, y, w, h: f32,
}

Meta :: struct {
	app, version, image, format, scale: string,
	size:                               MetaSize,
	frameTags:                          []string,
}

MetaSize :: struct {
	w, h: f32,
}

loadSpritesheet :: proc(
	path: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> ^Spritesheet {
	log.infof("Loading spritesheet from path %v", path)

	file, read_file_err := os.read_entire_file(path, allocator)
	if read_file_err != nil {
		log.errorf("Failed to read aseprite data file %v", read_file_err)
		return nil
	}

	spritesheet := new(Spritesheet, allocator)

	unmarshal_err := json.unmarshal(file, spritesheet, allocator = allocator)
	if unmarshal_err != nil {
		log.errorf("Failed to unmarshal aseprite data %v", read_file_err)
		return nil
	}

	return spritesheet
}

