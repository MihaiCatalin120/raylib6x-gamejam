package game

import rl "vendor:raylib"
import math "core:math"

run: bool
MAIN_PADDING :: 20
HEX_SIDE_LENGTH :: 40
HEX_SIDE_THICKNESS :: 4
HONEYCOMB_SIZE :: 6

Cell_Data :: struct {
    color: rl.Color,
    group: int,
}

cells_data: [HONEYCOMB_SIZE + 1][HONEYCOMB_SIZE + 1]Cell_Data

draw_hex_tile :: proc(top: rl.Vector2, color: rl.Color) {
    edge_color: rl.Color = {226, 224, 0, 255}
    pos_increment_unit: f32 = HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0)

    top_left: rl.Vector2 = top + { -pos_increment_unit, HEX_SIDE_LENGTH / 2 }
    top_right: rl.Vector2 = top + { pos_increment_unit, HEX_SIDE_LENGTH / 2 }
    rl.DrawLineEx(top, top_left, HEX_SIDE_THICKNESS, edge_color)
    rl.DrawLineEx(top, top_right, HEX_SIDE_THICKNESS, edge_color)
    rl.DrawTriangle(top, top_left, top_right, color)

    bottom_left: rl.Vector2 = top_left + {0, HEX_SIDE_LENGTH}
    bottom_right: rl.Vector2 = top_right + {0, HEX_SIDE_LENGTH}
    rl.DrawLineEx(top_left, bottom_left, HEX_SIDE_THICKNESS, edge_color)
    rl.DrawLineEx(top_right, bottom_right, HEX_SIDE_THICKNESS, edge_color)
    rl.DrawTriangle(top_left, bottom_left, top_right, color)
    rl.DrawTriangle(top_right, bottom_left, bottom_right, color)

    bottom: rl.Vector2 = bottom_left + { pos_increment_unit, HEX_SIDE_LENGTH / 2 }
    rl.DrawLineEx(bottom_left, bottom, HEX_SIDE_THICKNESS, edge_color)
    rl.DrawLineEx(bottom_right, bottom, HEX_SIDE_THICKNESS, edge_color)
    rl.DrawTriangle(bottom_left, bottom, bottom_right, color)
}

draw_hex_row :: proc(start_pos: rl.Vector2, level: int) {
    if math.abs(level) >= 4 do return

    row_index := HONEYCOMB_SIZE / 2 + level

    for i := 0; i < HONEYCOMB_SIZE - math.abs(level); i += 1 {
        draw_hex_tile(start_pos + {f32(i * HEX_SIDE_LENGTH) * math.sqrt_f32(3.0), 0}, cells_data[row_index][i].color)
    }

    if level == 0 {
        draw_hex_row(start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), -1.5 * HEX_SIDE_LENGTH}, level - 1)
        draw_hex_row(start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), 1.5 * HEX_SIDE_LENGTH}, level + 1)
    } else if level < 0 {
        draw_hex_row(start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), -1.5 * HEX_SIDE_LENGTH}, level - 1)
    } else {
        draw_hex_row(start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), 1.5 * HEX_SIDE_LENGTH}, level + 1)
    }
}

draw_dialogue_box :: proc(start_pos: rl.Vector2) {
    background: rl.Rectangle = {start_pos.x + 10, start_pos.y, 700, 170}
    // rl.DrawRectangleGradientEx(background, {144, 238, 144, 255}, {152, 251, 152, 255}, {236, 255, 220, 255}, {236, 255, 220, 255})
    rl.DrawRectangleRounded(background, 0.2, 20, {152, 251, 152, 255})

    border: rl.Rectangle = background
    rl.DrawRectangleRoundedLinesEx(border, 0.2, 20, 4, {69, 69, 69, 255})

    avatar: rl.Rectangle = {border.x + 10, border.y + 10, 150, 150}
    rl.DrawRectangleRec(avatar, rl.YELLOW)

    message: rl.Rectangle = {avatar.x + 160, avatar.y, 540, 150}
    rl.GuiLabel(message, "That blasted witch keeps hexing my comb and \nmessing up all the cells! Will you help me?\n\n  ...please?")

    draw_friendship_bar({100, 700})
}

draw_friendship_bar :: proc(start_pos: rl.Vector2) {

}

init :: proc() {
	run = true
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(720, 720, "Odin + Raylib on the web")

    //NOTE(mihai): this sucks
    cells_data = [HONEYCOMB_SIZE + 1][HONEYCOMB_SIZE + 1]Cell_Data{
        {
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
        },
        {
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
        },
        {
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
        },
        {
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
        },
        {
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
        },
        {
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
        },
        {
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
            { rl.WHITE, 0 },
        },
    }

    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 24)
    rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_LINE_SPACING), 24)
}

update :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground({255, 190, 66, 64})
	{
        draw_hex_row({200, 240}, 0)
        draw_dialogue_box({0, 540})
	}
	rl.EndDrawing()

	// Anything allocated using temp allocator is invalid after this.
	free_all(context.temp_allocator)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
parent_window_size_changed :: proc(w, h: int) {
}

shutdown :: proc() {
	rl.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			run = false
		}
	}

	return run
}
