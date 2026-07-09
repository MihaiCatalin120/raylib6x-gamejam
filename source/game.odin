package game

import fmt "core:fmt"
import math "core:math"
import rand "core:math/rand"
import strings "core:strings"
import rl "vendor:raylib"

run: bool
score: u8
current_level_finished: bool
won_game: bool
is_group_hovered: bool
is_group_selected: bool
new_group_index: int
grid_start_pos: rl.Vector2
meebee: Meebee
messages_win, messages_lose: [4][3]string
current_message: string

MAIN_PADDING :: 20
HEX_SIDE_LENGTH :: 40
HEX_SIDE_THICKNESS :: 4
HONEYCOMB_SIZE :: 6
MAX_LEVEL :: 20

Honey_Color_Target :: struct {
	r_min, r_max, g_min, g_max, b_min, b_max: u8,
}

Cell_Data :: struct {
	color:        rl.Color,
	group:        int,
	hovered:      bool,
	selected:     bool,
	valid_option: bool,
}

Meebee_Feeling :: enum {
	LOVE,
	HAPPY,
	MEH,
	SAD,
}

Meebee :: struct {
	happy, meh, sad, love: rl.Texture2D,
	feeling:               Meebee_Feeling,
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
	radius := f32(HEX_SIDE_LENGTH - HEX_SIDE_THICKNESS / 4)
	rotation: f32 = 90.0

	rl.DrawPoly(center, 6, radius, rotation, cell_data.color)
	// rl.DrawText(rl.TextFormat("%d", cell_data.group), i32(center.x), i32(center.y), 24, rl.BLACK)

	outline_color: rl.Color = rl.YELLOW
	if !won_game {
		if cell_data.selected {
			outline_color = rl.RED
		}
		if cell_data.valid_option {
			outline_color = rl.WHITE
		}
		if cell_data.hovered {
			outline_color = rl.BLACK
		}
	}
	if outline_color.a > 0 do rl.DrawPolyLinesEx(center, 6, radius, rotation, HEX_SIDE_THICKNESS, outline_color)
}

draw_won_text :: proc() {
	if !won_game do return

	start_x: i32 = 290
	y1: i32 = 160
	y2: i32 = 280
	rl.DrawText("Y", start_x, y1, 48, rl.BLACK)
	rl.DrawText("O", start_x + 1.75 * HEX_SIDE_LENGTH, y1, 48, rl.BLACK)
	rl.DrawText("U", start_x + 3.5 * HEX_SIDE_LENGTH, y1, 48, rl.BLACK)

	rl.DrawText("W", start_x, y2, 48, rl.BLACK)
	rl.DrawText("O", start_x + 1.75 * HEX_SIDE_LENGTH, y2, 48, rl.BLACK)
	rl.DrawText("N", start_x + 3.5 * HEX_SIDE_LENGTH, y2, 48, rl.BLACK)

	rl.DrawText("!", 265 + 1.75 * HEX_SIDE_LENGTH, 340, 48, rl.BLACK)
	rl.DrawText("!", 265 + 3.5 * HEX_SIDE_LENGTH, 340, 48, rl.BLACK)
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

	draw_won_text()

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
	roundness: f32 = 0.2
	background: rl.Rectangle = {start_pos.x + 10, start_pos.y, 700, 170}
	// rl.DrawRectangleGradientEx(background, {144, 238, 144, 255}, {152, 251, 152, 255}, {236, 255, 220, 255}, {236, 255, 220, 255})
	rl.DrawRectangleRounded(background, roundness, 20, {152, 251, 152, 255})

	border: rl.Rectangle = background
	rl.DrawRectangleRoundedLinesEx(border, roundness, 20, 4, {69, 69, 69, 255})

	avatar_texture: rl.Texture2D
	switch meebee.feeling {
	case .HAPPY:
		avatar_texture = meebee.happy
	case .MEH:
		avatar_texture = meebee.meh
	case .SAD:
		avatar_texture = meebee.sad
	case .LOVE:
		avatar_texture = meebee.love
	}

	source_avatar: rl.Rectangle = {0, 0, f32(avatar_texture.width), f32(avatar_texture.height)}
	avatar: rl.Rectangle = {border.x + 10, border.y + 10, 150, 150}
	rl.DrawRectangleRec(avatar, rl.YELLOW)
	rl.DrawTexturePro(avatar_texture, source_avatar, avatar, {0, 0}, 0, rl.WHITE)

	message: rl.Rectangle = {avatar.x + 160, avatar.y, 540, 150}
	rl.GuiLabel(message, strings.clone_to_cstring(current_message))
}

draw_friendship_bar :: proc(start_pos: rl.Vector2) {
	roundness: f32 = 1.0
	background: rl.Rectangle = {
		start_pos.x + 10,
		start_pos.y,
		f32(700 * int(score) / MAX_LEVEL),
		20,
	}

	rl.DrawRectangleRounded(
		background,
		roundness,
		20,
		{
			// honey_color_target.r_max / 2 + honey_color_target.r_min / 2,
			// honey_color_target.g_max / 2 + honey_color_target.g_min / 2,
			// honey_color_target.b_max / 2 + honey_color_target.b_min / 2,
			251,
			255,
			0,
			255,
		},
	)

	border: rl.Rectangle = {start_pos.x + 10, start_pos.y, 700, 20}
	rl.DrawRectangleRoundedLinesEx(border, roundness, 20, 4, {69, 69, 69, 255})
}

reset_cell_data :: proc() {
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			r := u8(rand.int31() % 255)
			g := u8(rand.int31() % 255)
			// b := u8(rand.int31() % 255)
			b := honey_color_target.b_max / 2 + honey_color_target.b_min / 2

			for r >= honey_color_target.r_min &&
			    r <= honey_color_target.r_max &&
			    g >= honey_color_target.g_min &&
			    g <= honey_color_target.g_max &&
			    b >= honey_color_target.b_min &&
			    b <= honey_color_target.b_max {
				r = u8(rand.int31() % 255)
				g = u8(rand.int31() % 255)
				// b = u8(rand.int31() % 255)
				b = honey_color_target.b_max / 2 + honey_color_target.b_min / 2
			}

			cells_data[row][col] = {
				{r, g, b, 200},
				row * HONEYCOMB_SIZE + col,
				false,
				false,
				false,
			}
		}
	}

	new_group_index = (HONEYCOMB_SIZE + 1) * HONEYCOMB_SIZE
	current_level_finished = false
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

set_hovered_group :: proc(group: int) {
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			if cells_data[row][col].group == group do cells_data[row][col].hovered = true
			if -1 == group do cells_data[row][col].hovered = false
		}
	}
}

set_selected_group :: proc(group: int) {
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			if cells_data[row][col].group == group do cells_data[row][col].selected = true
			if -1 == group {
				cells_data[row][col].selected = false
				cells_data[row][col].valid_option = false
			}
		}
	}
}

merge_groups :: proc(target_group: int) -> (rl.Color, int) {
	if !is_group_selected do return {0, 0, 0, 0}, -1

	source: [2]int
	source_group: int
	target: [2]int
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			if cells_data[row][col].selected {
				source = {row, col}
				source_group = cells_data[row][col].group
			}
			if cells_data[row][col].group == target_group do target = {row, col}
		}
	}

	source_merge_ratio := 0.5
	target_merge_ratio := 0.5
	new_color: rl.Color = {
		u8(
			f64(cells_data[source.x][source.y].color.r) * source_merge_ratio +
			f64(cells_data[target.x][target.y].color.r) * target_merge_ratio,
		),
		u8(
			f64(cells_data[source.x][source.y].color.g) * source_merge_ratio +
			f64(cells_data[target.x][target.y].color.g) * target_merge_ratio,
		),
		u8(
			f64(cells_data[source.x][source.y].color.b) * source_merge_ratio +
			f64(cells_data[target.x][target.y].color.b) * target_merge_ratio,
		),
		255,
	}

	new_group := new_group_index
	new_group_index += 1

	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			if cells_data[row][col].group == source_group ||
			   cells_data[row][col].group == target_group {
				cells_data[row][col].group = new_group
				cells_data[row][col].color = new_color
				cells_data[row][col].valid_option = false
			}
		}
	}

	return new_color, new_group
}

check_winning_color :: proc(color: rl.Color) -> bool {
	if color.r < honey_color_target.r_min || color.r > honey_color_target.r_max do return false
	if color.g < honey_color_target.g_min || color.g > honey_color_target.g_max do return false
	if color.b < honey_color_target.b_min || color.b > honey_color_target.b_max do return false

	return true
}

check_stuck_grid :: proc() -> bool {
	prev_group := -1
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			if prev_group != -1 && (prev_group != cells_data[row][col].group) do return false
			else do prev_group = cells_data[row][col].group
		}
	}

	return true
}

pick_message :: proc(happy: bool) {
	message_pool: [4][3]string

	if happy do message_pool = messages_win
	else do message_pool = messages_lose

	tier := score / 5
	pick := rl.GetRandomValue(0, 2)

	current_message = message_pool[tier][pick]
}

set_winning_board :: proc() {
	is_group_selected = false
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			cells_data[row][col].color = {0, 0, 0, 0}
			cells_data[row][col].selected = false
			cells_data[row][col].valid_option = false
		}
	}
}

process_win :: proc() {
	fmt.println("DEBUG: Won round!!!!!")
	score += 3
	if score >= 20 {
		score = 20
		set_winning_board()
		won_game = true
		current_message = "I will forever grateful for all the help you have\ngiven me! Hope we see each other soon!"
		meebee.feeling = .LOVE
		return
	}
	current_level_finished = true
	reset_cell_data()
	meebee.feeling = .HAPPY
	pick_message(true)
}

process_lose :: proc() {
	fmt.println("DEBUG: Lost round......")
	if score > 0 do score -= 1
	current_level_finished = true
	reset_cell_data()
	if score > 0 do meebee.feeling = .MEH
	else do meebee.feeling = .SAD
	pick_message(false)
}

compute_cell_state :: proc(center: rl.Vector2, cell_data: ^Cell_Data) {
	radius := f32(HEX_SIDE_LENGTH - HEX_SIDE_THICKNESS)

	hexagon_points := get_hexagon_points(center, radius)
	points: [6]rl.Vector2 = {
		hexagon_points.top,
		hexagon_points.top_left,
		hexagon_points.bottom_left,
		hexagon_points.bottom,
		hexagon_points.bottom_right,
		hexagon_points.top_right,
	}

	hovered := rl.CheckCollisionPointPoly(rl.GetMousePosition(), &points[0], 6)
	if hovered && !won_game {
		cell_data.hovered = true
		set_hovered_group(-1)
		set_hovered_group(cell_data.group)

		if rl.IsMouseButtonPressed(.LEFT) {
			if !is_group_selected {
				is_group_selected = true
				set_selected_group(cell_data.group)
			} else {
				if cell_data.valid_option {
					new_color, new_group := merge_groups(cell_data.group)
					assert(
						new_group != -1,
						"Merge group should always succeed, and return a valid new group at the end",
					)
					if check_winning_color(new_color) do process_win()
					else if check_stuck_grid() do process_lose()

					is_group_selected = true
					set_selected_group(cell_data.group)
				} else {
					is_group_selected = true
					set_selected_group(-1)
					set_selected_group(cell_data.group)
				}

			}
		}
	}
}

compute_cell_states :: proc(start_pos: rl.Vector2, level: int) {
	if math.abs(level) >= 4 do return

	row_index := HONEYCOMB_SIZE / 2 + level

	for i := 0; i < HONEYCOMB_SIZE - math.abs(level); i += 1 {
		compute_cell_state(
			start_pos + {f32(i * HEX_SIDE_LENGTH) * math.sqrt_f32(3.0), 0},
			&cells_data[row_index][i],
		)
	}

	if level == 0 {
		compute_cell_states(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), -1.5 * HEX_SIDE_LENGTH},
			level - 1,
		)
		compute_cell_states(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), 1.5 * HEX_SIDE_LENGTH},
			level + 1,
		)
	} else if level < 0 {
		compute_cell_states(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), -1.5 * HEX_SIDE_LENGTH},
			level - 1,
		)
	} else {
		compute_cell_states(
			start_pos + {HEX_SIDE_LENGTH / 2 * math.sqrt_f32(3.0), 1.5 * HEX_SIDE_LENGTH},
			level + 1,
		)
	}
}

mark_valid_moves :: proc() {
	offsets_top: [6][2]int = {{1, 0}, {1, 1}, {0, 1}, {-1, 0}, {-1, -1}, {0, -1}}
	offsets_middle: [6][2]int = {{1, 0}, {0, 1}, {1, -1}, {-1, 0}, {-1, -1}, {0, -1}}
	offsets_bottom: [6][2]int = {{1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {0, -1}, {1, -1}}
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		col_limit := HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row))
		offsets: [6][2]int

		if row > HONEYCOMB_SIZE / 2 do offsets = offsets_bottom
		else if row == HONEYCOMB_SIZE / 2 do offsets = offsets_middle
		else do offsets = offsets_top

		for col := 0; col < col_limit; col += 1 {
			if cells_data[row][col].selected do for i := 0; i < 6; i += 1 {
				neighbour: [2]int = {row, col} + offsets[i]
				if neighbour.x < 0 do continue
				if neighbour.x >= HONEYCOMB_SIZE + 1 do continue
				if neighbour.y < 0 do continue

				if col == col_limit - 1 {
					if row > HONEYCOMB_SIZE / 2 {
						if neighbour.x < row {
							if neighbour.y > col_limit do continue
						} else do if neighbour.y >= col_limit do continue
					} else if row == HONEYCOMB_SIZE / 2 {
						if neighbour.y >= col_limit do continue
					} else if row < HONEYCOMB_SIZE / 2 {
						if neighbour.x > row {
							if neighbour.y > col_limit do continue
						} else do if neighbour.y >= col_limit do continue
					}

				} else do if neighbour.y >= col_limit do continue

				if !cells_data[neighbour.x][neighbour.y].selected do cells_data[neighbour.x][neighbour.y].valid_option = true
			}
		}
	}
}

load_messages :: proc() {
	messages_win = {
		{
			"Ooh, thank you!",
			"Thanks! I think I have it from here...",
			"Did not expect you to do it at all, thank you!",
		},
		{
			"Thank you so much!",
			"I think I need to clean the jars, has been a\nwhile since I got anything...",
			"",
		},
		{
			"Wait, are you also a bee? You seem to figure\nthis out way better than I expected!",
			"I'll make sure to keep some honey for you\nafter all of this",
			"Are you also a witch hunter by any chance?\nMaybe I can get rid of this forever",
		},
		{
			"If anybody annoys you ever, just reach out\nfor me, okay?",
			"At this point you could take care of the comb\nand I'll just defend it",
			"Ooh, thank you!",
		},
	}

	messages_lose = {
		{
			"It's okay... maybe it will arrange itself after I\nwake up from a nap",
			"At least you tried...",
			"I will manage, it's fine...",
		},
		{
			"Oof, you were so close...",
			"Almost.. it's alright",
			"The cells are too warped, maybe I should leave\nit as is...",
		},
		{
			"I was minding my business.. and the witch pushed me of the flower! Of course I tried to sting her..",
			"Maybe it will be faster if I learn the spell to\nreverse this..",
			"I will make sure witches will have +100% \"discount\" on my honey jars! Yes, 100%, plus an extra sting pack while at it",
		},
		{
			"Maybe I am too foolish to think I can do it all today...",
			"You were too kind already, it is fine...",
			"I will manage, it's fine...",
		},
	}
}

init :: proc() {
	run = true
	current_level_finished = true
	won_game = false
	is_group_hovered = false
	is_group_selected = false
	new_group_index = (HONEYCOMB_SIZE + 1) * HONEYCOMB_SIZE
	honey_color_target = {180, 255, 120, 200, 20, 90}
	grid_start_pos = {200, 240}

	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(720, 720, "Help Meebee!")

	meebee = {
		rl.LoadTexture("assets/meebee.png"),
		rl.LoadTexture("assets/meebee_meh.png"),
		rl.LoadTexture("assets/meebee_sad.png"),
		rl.LoadTexture("assets/meebee_love.png"),
		Meebee_Feeling.SAD,
	}

	load_messages()

	current_message = "That blasted witch keeps cursing my comb and \nmessing up all the cells! Will you help me?\n\n...please?"

	if current_level_finished do reset_cell_data()

	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 24)
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_LINE_SPACING), 24)
}

update :: proc() {
	if should_flush_hovered_group(grid_start_pos, 0) {
		is_group_hovered = false
		set_hovered_group(-1)
	}
	compute_cell_states(grid_start_pos, 0)
	if is_group_selected do mark_valid_moves()

	rl.BeginDrawing()
	rl.ClearBackground({255, 190, 66, 64})
	{
		draw_hex_row(grid_start_pos, 0)
		draw_friendship_bar({0, 500})
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
	rl.UnloadTexture(meebee.happy)
	rl.UnloadTexture(meebee.meh)
	rl.UnloadTexture(meebee.sad)
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
