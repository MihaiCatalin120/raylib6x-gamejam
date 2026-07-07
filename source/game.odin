package game

import math "core:math"
import rand "core:math/rand"
import rl "vendor:raylib"

run: bool
level_finished: bool
hovered_group: int
grid_start_pos: rl.Vector2
MAIN_PADDING :: 20
HEX_SIDE_LENGTH :: 40
HEX_SIDE_THICKNESS :: 4
HONEYCOMB_SIZE :: 6

Honey_Color_Target :: struct {
	r_min, r_max, g_min, g_max, b_min, b_max: u8,
}

Cell_Data :: struct {
	color: rl.Color,
	group: int,
}

Hexagon_Points :: struct {
	top, top_left, bottom_left, bottom, bottom_right, top_right: rl.Vector2,
}

honey_color_target: Honey_Color_Target
cells_data: [HONEYCOMB_SIZE + 1][HONEYCOMB_SIZE]Cell_Data

get_hexagon_points :: proc(center: rl.Vector2, radius: f32) -> Hexagon_Points {
	pos_increment_unit: f32 = radius / 2 * math.sqrt_f32(3.0)
	top: rl.Vector2 = center + {0, -radius}
	top_left: rl.Vector2 = top + {-pos_increment_unit, radius / 2}
	top_right: rl.Vector2 = top + {pos_increment_unit, radius / 2}
	bottom_left: rl.Vector2 = top_left + {0, radius}
	bottom_right: rl.Vector2 = top_right + {0, radius}
	bottom: rl.Vector2 = bottom_left + {pos_increment_unit, radius / 2}

	return {top, top_left, bottom_left, bottom, bottom_right, top_right}
}

draw_hex_tile :: proc(center: rl.Vector2, cell_data: Cell_Data) {
	radius := f32(HEX_SIDE_LENGTH - HEX_SIDE_THICKNESS)
	rotation: f32 = 90.0
	// Compute vertices, but draw only the fill first
	hexagon_points := get_hexagon_points(center, radius)
	points: [6]rl.Vector2 = {
		hexagon_points.top,
		hexagon_points.top_left,
		hexagon_points.bottom_left,
		hexagon_points.bottom,
		hexagon_points.bottom_right,
		hexagon_points.top_right,
	}

	rl.DrawPoly(center, 6, radius, rotation, cell_data.color)

	hovered := rl.CheckCollisionPointPoly(rl.GetMousePosition(), &points[0], 6)
	if hovered {
		hovered_group = cell_data.group
	}
	if hovered || (hovered_group > 0 && cell_data.group == hovered_group) {
		rl.DrawPolyLinesEx(center, 6, radius, rotation, HEX_SIDE_THICKNESS, rl.BLACK)
	}
}

draw_hex_row :: proc(start_pos: rl.Vector2, level: int) {
	if math.abs(level) >= 4 do return

	row_index := HONEYCOMB_SIZE / 2 + level

	for i := 0; i < HONEYCOMB_SIZE - math.abs(level); i += 1 {
		draw_hex_tile(
			start_pos + {f32(i * HEX_SIDE_LENGTH) * math.sqrt_f32(3.0), 0},
			cells_data[row_index][i],
		)
	}

	if level == 0 {
		draw_hex_row(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), -1.5 * HEX_SIDE_LENGTH},
			level - 1,
		)
		draw_hex_row(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), 1.5 * HEX_SIDE_LENGTH},
			level + 1,
		)
	} else if level < 0 {
		draw_hex_row(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), -1.5 * HEX_SIDE_LENGTH},
			level - 1,
		)
	} else {
		draw_hex_row(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), 1.5 * HEX_SIDE_LENGTH},
			level + 1,
		)
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
	rl.GuiLabel(
		message,
		"That blasted witch keeps hexing my comb and \nmessing up all the cells! Will you help me?\n\n...please?",
	)

	draw_friendship_bar({100, 700})
}

draw_friendship_bar :: proc(start_pos: rl.Vector2) {

}

reset_cell_data :: proc() {
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			r := u8(rand.int31() % 255)
			g := u8(rand.int31() % 255)
			b := u8(rand.int31() % 255)

			for r >= honey_color_target.r_min && r <= honey_color_target.r_max do r = u8(rand.int31() % 255)
			for g >= honey_color_target.g_min && g <= honey_color_target.g_max do g = u8(rand.int31() % 255)
			for b >= honey_color_target.b_min && b <= honey_color_target.b_max do b = u8(rand.int31() % 255)

			cells_data[row][col] = {{r, g, b, 200}, col > 2 && col < 5 ? 1 : -1}
		}
	}

	level_finished = false
}

should_flush_hovered_group :: proc(start_pos: rl.Vector2, level: int) -> bool {
	if math.abs(level) >= 4 do return true

	for i := 0; i < HONEYCOMB_SIZE - math.abs(level); i += 1 {
		radius := f32(HEX_SIDE_LENGTH - HEX_SIDE_THICKNESS)
		center := start_pos + {f32(i * HEX_SIDE_LENGTH) * math.sqrt_f32(3.0), 0}
		hexagon_points := get_hexagon_points(center, radius)
		points: [6]rl.Vector2 = {
			hexagon_points.top,
			hexagon_points.top_left,
			hexagon_points.bottom_left,
			hexagon_points.bottom,
			hexagon_points.bottom_right,
			hexagon_points.top_right,
		}

		if rl.CheckCollisionPointPoly(rl.GetMousePosition(), &points[0], 6) do return false
	}

	if level == 0 {
		return(
			should_flush_hovered_group(
				start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), -1.5 * HEX_SIDE_LENGTH},
				level - 1,
			) &&
			should_flush_hovered_group(
				start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), 1.5 * HEX_SIDE_LENGTH},
				level + 1,
			) \
		)
	} else if level < 0 {
		return should_flush_hovered_group(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), -1.5 * HEX_SIDE_LENGTH},
			level - 1,
		)
	} else {
		return should_flush_hovered_group(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), 1.5 * HEX_SIDE_LENGTH},
			level + 1,
		)
	}

	return true
}

init :: proc() {
	run = true
	level_finished = true
	hovered_group = -1
	honey_color_target = {180, 255, 120, 200, 20, 90}
	grid_start_pos = {200, 240}

	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(720, 720, "Help Meebee!")

	if level_finished do reset_cell_data()

	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 24)
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_LINE_SPACING), 24)
}

update :: proc() {
	if should_flush_hovered_group(grid_start_pos, 0) do hovered_group = -1
	rl.BeginDrawing()
	rl.ClearBackground({255, 190, 66, 64})
	{
		draw_hex_row(grid_start_pos, 0)
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
