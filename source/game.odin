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
show_help: bool
should_restart: bool
new_group_index: int
grid_start_pos: rl.Vector2
meebee: Meebee
messages_win, messages_lose: [4][3]string
current_message: string
message_timer: f32
merge_timer: f32
merge_target_color: rl.Color
merge_target_group: int
font: rl.Font
color_timer: f32
muted: bool

HELP_PADDING :: 20
HEX_SIDE_LENGTH :: 40
HEX_SIDE_THICKNESS :: 4
HONEYCOMB_SIZE :: 6
MAX_LEVEL :: 20
MERGE_MAX_TIMER :: 0.25

Honey_Color_Target :: struct {
	r_min, r_max, g_min, g_max, b_min, b_max: u8,
}

Cell_Data :: struct {
	color:             rl.Color,
	merge_start_color: rl.Color,
	group:             int,
	hovered:           bool,
	selected:          bool,
	valid_option:      bool,
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

Sfx :: struct {
	lose, merge, select, win_round, won_game: rl.Sound,
}

honey_color_target: Honey_Color_Target
cells_data: [HONEYCOMB_SIZE + 1][HONEYCOMB_SIZE]Cell_Data
help_tiles: [9]Cell_Data
game_sfx: Sfx
background_music: rl.Music
background_music_1: rl.Music
background_music_2: rl.Music

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
			outline_color = {
				u8(math.abs(math.sin_f32(color_timer)) * 255),
				u8(math.abs(math.sin_f32(color_timer)) * 255),
				255,
				255,
			}
		}
		if cell_data.hovered {
			outline_color = rl.BLACK
		}
	}
	if outline_color.a > 0 do rl.DrawPolyLinesEx(center, 6, radius, rotation, HEX_SIDE_THICKNESS, outline_color)
}

draw_won_text :: proc() {
	if !won_game do return

	start_x: f32 = 290
	y1: f32 = 160
	y2: f32 = 280
	rl.DrawTextEx(font, "Y", {start_x, y1}, 48, 1.0, rl.BLACK)
	rl.DrawTextEx(font, "O", {start_x + 1.75 * HEX_SIDE_LENGTH, y1}, 48, 1.0, rl.BLACK)
	rl.DrawTextEx(font, "U", {start_x + 3.5 * HEX_SIDE_LENGTH, y1}, 48, 1.0, rl.BLACK)

	rl.DrawTextEx(font, "W", {start_x, y2}, 48, 1.0, rl.BLACK)
	rl.DrawTextEx(font, "O", {start_x + 1.75 * HEX_SIDE_LENGTH, y2}, 48, 1.0, rl.BLACK)
	rl.DrawTextEx(font, "N", {start_x + 3.5 * HEX_SIDE_LENGTH, y2}, 48, 1.0, rl.BLACK)

	// rl.DrawTextEx(font, "!", {265 + 1.75 * HEX_SIDE_LENGTH, 340}, 48, 2.0, rl.BLACK)
	// rl.DrawTextEx(font, "!", {265 + 3.5 * HEX_SIDE_LENGTH, 340}, 48, 2.0, rl.BLACK)
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

	chars_per_second: f32 = 30
	message: rl.Rectangle = {avatar.x + 160, avatar.y, 540, 150}
	message_progress := min(len(current_message), int(chars_per_second * message_timer))
	rl.GuiLabel(message, strings.clone_to_cstring(current_message[:message_progress]))

	if won_game {
		restart: rl.Rectangle = {message.x + 410, message.y + 120, 100, 30}
		if rl.GuiButton(restart, "Restart") {
			should_restart = true
			rl.PlaySound(game_sfx.select)
		}
	} else {
		help: rl.Rectangle = {message.x + 450, message.y + 120, 60, 30}
		if rl.GuiButton(help, "Help") {
			show_help = true
			rl.PlaySound(game_sfx.select)
		}
	}
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
				{},
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

get_selected_group :: proc() -> int {
	if !is_group_selected do return -1
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			if cells_data[row][col].selected do return cells_data[row][col].group
		}
	}

	return -1
}

compute_merge_colors :: proc() {
	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			if cells_data[row][col].group == merge_target_group {
				start: rl.Color = cells_data[row][col].merge_start_color
				progress: f32 = merge_timer / MERGE_MAX_TIMER
				cells_data[row][col].color = {
					u8(f32(start.r) + (f32(merge_target_color.r) - f32(start.r)) * progress),
					u8(f32(start.g) + (f32(merge_target_color.g) - f32(start.g)) * progress),
					u8(f32(start.b) + (f32(merge_target_color.b) - f32(start.b)) * progress),
					u8(f32(start.a) + (f32(merge_target_color.a) - f32(start.a)) * progress),
				}
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

	merge_timer = 0

	new_group := new_group_index
	new_group_index += 1

	for row := 0; row < HONEYCOMB_SIZE + 1; row += 1 {
		for col := 0; col < HONEYCOMB_SIZE - (math.abs(HONEYCOMB_SIZE / 2 - row)); col += 1 {
			if cells_data[row][col].group == source_group ||
			   cells_data[row][col].group == target_group {
				cells_data[row][col].merge_start_color = cells_data[row][col].color
				cells_data[row][col].group = new_group
				merge_target_color = new_color
				merge_target_group = new_group
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
	message_timer = 0
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
	if score >= 10 {
		background_music = background_music_2
		rl.PlayMusicStream(background_music)
	}
	if score >= MAX_LEVEL {
		score = MAX_LEVEL
		set_winning_board()
		won_game = true
		current_message = "I will forever grateful for all the help you have\ngiven me! Hope we see each other soon!"
		message_timer = 0
		meebee.feeling = .LOVE
		rl.StopMusicStream(background_music)
		rl.PlaySound(game_sfx.won_game)
		return
	}
	current_level_finished = true
	reset_cell_data()
	meebee.feeling = .HAPPY
	pick_message(true)
	rl.PlaySound(game_sfx.win_round)
}

process_lose :: proc() {
	fmt.println("DEBUG: Lost round......")
	if score > 0 do score -= 1
	if score < 10 {
		background_music = background_music_1
		rl.PlayMusicStream(background_music)
	}
	current_level_finished = true
	reset_cell_data()
	if score > 0 do meebee.feeling = .MEH
	else do meebee.feeling = .SAD
	pick_message(false)
	rl.PlaySound(game_sfx.lose)
}

compute_cell_state :: proc(center: rl.Vector2, cell_data: ^Cell_Data) {
	if won_game || show_help do return

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
	if hovered {
		cell_data.hovered = true
		set_hovered_group(-1)
		set_hovered_group(cell_data.group)

		if rl.IsMouseButtonPressed(.LEFT) {
			if !is_group_selected {
				is_group_selected = true
				set_selected_group(cell_data.group)
				rl.PlaySound(game_sfx.select)
			} else {
				if cell_data.valid_option {
					new_color, new_group := merge_groups(cell_data.group)
					assert(
						new_group != -1,
						"Merge group should always succeed, and return a valid new group at the end",
					)
					if check_winning_color(new_color) {
						process_win()
						return
					}

					if check_stuck_grid() {
						process_lose()
						return
					}

					set_selected_group(cell_data.group)
					rl.PlaySound(game_sfx.merge)
				} else {
					selected_group := get_selected_group()
					// assert(selected_group != -1, "A group should have selected status when the global variable is_group_selected is true")
					set_selected_group(-1)
					is_group_selected = false
					if selected_group != cell_data.group {
						is_group_selected = true
						set_selected_group(cell_data.group)
					}
					rl.PlaySound(game_sfx.select)
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
			"I, Meebee, promise will pay back all the help\nreceived!",
		},
		{
			"Wait, are you also a bee? You seem to figure\nthis out way better than I expected!",
			"I'll make sure to keep some honey for you\nafter all of this!",
			"Are you also a witch hunter by any chance?\nMaybe I can get rid of this forever...",
		},
		{
			"If anybody annoys you ever, just reach out\nfor me, okay?",
			"At this point you could take care of the honeycomb\nand I'll just defend it...",
			"You make Mee Bee so happy!\n\n...hope you like puns",
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
			"I was minding my business.. and the witch pushed\nme of the flower!\n\n...of course I tried to sting her!",
			"Maybe it will be faster if I learn the spell to\nreverse this..",
			"I will make sure witches will have +100%\n\"discount\" on my honey jars!\n\nYes, 100%, plus an extra sting pack while at it!",
		},
		{
			"Maybe I am too foolish to think I can do it all\ntoday...",
			"You were too kind already, it is fine...",
			"Don't stress to much, you did way better than\nme at least...",
		},
	}
}

draw_help :: proc() {
	rl.DrawRectangle(0, 0, 720, 720, {0, 0, 0, 128})

	roundness: f32 = 0.02
	background: rl.Rectangle = {
		HELP_PADDING,
		HELP_PADDING,
		720 - 2 * HELP_PADDING,
		720 - 2 * HELP_PADDING,
	}
	// rl.DrawRectangleGradientEx(background, {144, 238, 144, 255}, {152, 251, 152, 255}, {236, 255, 220, 255}, {236, 255, 220, 255})
	rl.DrawRectangleRounded(background, roundness, 20, {152, 251, 152, 255})

	border: rl.Rectangle = background
	rl.DrawRectangleRoundedLinesEx(border, roundness, 20, 4, {69, 69, 69, 255})

	close: rl.Rectangle = {720 - 120, 2 * HELP_PADDING, 80, 30}
	if rl.GuiButton(close, "Close") {
		show_help = false
		rl.PlaySound(game_sfx.select)
	}

	help: rl.Rectangle = {
		border.x + HELP_PADDING + 10,
		border.y + HELP_PADDING + 60,
		border.width - 2 * HELP_PADDING - 10,
		border.height - 2 * HELP_PADDING,
	}
	rl.GuiLabel(
		help,
		"Help Meebee gather as much honey as possible!\nCombine honeycomb cells to advance further and gain\nmore trust.\n\nAny two adjacent cells can be combined, once they do\nit is considered a single group.\n\nYou can combine groups together by merging their\nouter-layer cells.\n\nHave fun!",
	)

	start_pos: rl.Vector2 = {80, 120}
	for i in 0 ..< len(help_tiles) {
		draw_hex_tile(
			start_pos + {f32(i * HEX_SIDE_LENGTH) * math.sqrt_f32(3.0), 0},
			help_tiles[i],
		)
	}
	start_pos = {80, 600}
	for i in 0 ..< len(help_tiles) {
		draw_hex_tile(
			start_pos + {f32(i * HEX_SIDE_LENGTH) * math.sqrt_f32(3.0), 0},
			help_tiles[len(help_tiles) - i - 1],
		)
	}
}

restart_game :: proc() {
	reset_cell_data()

	won_game = false
	is_group_hovered = false
	is_group_selected = false
	show_help = false
	meebee.feeling = .SAD
	score = 0
	current_message = "That blasted witch keeps cursing my honeycomb and \nmessing up all the cells! Will you help me?\n\n...please?"
	message_timer = 0
	background_music = background_music_1
	rl.StopMusicStream(background_music)
	rl.PlayMusicStream(background_music)

	should_restart = false
}

toggleMuted :: proc() {
	if !muted {
		rl.SetMusicVolume(background_music, 0)
		rl.SetMusicVolume(background_music_1, 0)
		rl.SetMusicVolume(background_music_2, 0)

		rl.SetSoundVolume(game_sfx.lose, 0)
		rl.SetSoundVolume(game_sfx.merge, 0)
		rl.SetSoundVolume(game_sfx.select, 0)
		rl.SetSoundVolume(game_sfx.win_round, 0)
		rl.SetSoundVolume(game_sfx.won_game, 0)
	} else {
		rl.SetMusicVolume(background_music, 0.3)
		rl.SetMusicVolume(background_music_1, 0.3)
		rl.SetMusicVolume(background_music_2, 0.3)

		rl.SetSoundVolume(game_sfx.lose, 1)
		rl.SetSoundVolume(game_sfx.merge, 1)
		rl.SetSoundVolume(game_sfx.select, 1)
		rl.SetSoundVolume(game_sfx.win_round, 0.8)
		rl.SetSoundVolume(game_sfx.won_game, 0.8)
	}

	muted = !muted
}

generate_help_tiles :: proc() {
	for i in 0 ..< len(help_tiles) {
		help_tiles[i] = {
			{
				u8(
					rl.GetRandomValue(
						i32(honey_color_target.r_min),
						i32(honey_color_target.r_max),
					),
				),
				u8(
					rl.GetRandomValue(
						i32(honey_color_target.g_min),
						i32(honey_color_target.g_max),
					),
				),
				55,
				255,
			},
			{},
			-1,
			false,
			false,
			false,
		}
	}
}

init :: proc() {
	run = true
	current_level_finished = true
	won_game = false
	is_group_hovered = false
	is_group_selected = false
	show_help = false
	should_restart = false
	new_group_index = (HONEYCOMB_SIZE + 1) * HONEYCOMB_SIZE
	honey_color_target = {180, 255, 120, 200, 20, 90}
	grid_start_pos = {200, 240}
	muted = false

	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(720, 720, "Help Meebee!")
	rl.InitAudioDevice()

	meebee = {
		rl.LoadTexture("assets/meebee.png"),
		rl.LoadTexture("assets/meebee_meh.png"),
		rl.LoadTexture("assets/meebee_sad.png"),
		rl.LoadTexture("assets/meebee_love.png"),
		Meebee_Feeling.SAD,
	}

	game_sfx = {
		rl.LoadSound("assets/lose.wav"),
		rl.LoadSound("assets/merge.wav"),
		rl.LoadSound("assets/select.wav"),
		rl.LoadSound("assets/win_round.wav"),
		rl.LoadSound("assets/won_game.wav"),
	}

	rl.SetSoundVolume(game_sfx.win_round, 0.8)
	rl.SetSoundVolume(game_sfx.won_game, 0.8)

	background_music_1 = rl.LoadMusicStream("assets/background1.wav")
	background_music_2 = rl.LoadMusicStream("assets/background2.wav")
	background_music = background_music_1
	rl.SetMusicVolume(background_music, 0.3)
	rl.SetMusicVolume(background_music_1, 0.3)
	rl.SetMusicVolume(background_music_2, 0.3)
	rl.PlayMusicStream(background_music)
	load_messages()

	generate_help_tiles()

	current_message = "That blasted witch keeps cursing my honeycomb and \nmessing up all the cells! Will you help me?\n\n...please?"
	message_timer = 0
	merge_timer = 0

	if current_level_finished do reset_cell_data()

	// Font source: https://www.dafont.com/militech.font (Adam Rucki)
	font = rl.LoadFont("assets/militech.ttf")
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 24)
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_LINE_SPACING), 24)
	rl.GuiSetFont(font)
}

update :: proc() {
	message_timer += rl.GetFrameTime()
	color_timer += rl.GetFrameTime() * 2
	merge_timer += rl.GetFrameTime()

	if should_restart do restart_game()
	rl.UpdateMusicStream(background_music)
	if should_flush_hovered_group(grid_start_pos, 0) {
		is_group_hovered = false
		set_hovered_group(-1)
	}
	if merge_timer <= MERGE_MAX_TIMER do compute_merge_colors()
	compute_cell_states(grid_start_pos, 0)
	if is_group_selected do mark_valid_moves()

	rl.BeginDrawing()
	rl.ClearBackground({255, 190, 66, 64})
	{
		draw_hex_row(grid_start_pos, 0)
		draw_friendship_bar({0, 500})
		draw_dialogue_box({0, 540})
		if show_help do draw_help()
		if !show_help {
			mute: rl.Rectangle = {720 - 100, 450, 80, 30}
			if rl.GuiButton(mute, muted ? "Unmute" : "Mute") do toggleMuted()
		}
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
	rl.UnloadFont(font)
	rl.CloseWindow()

	rl.UnloadSound(game_sfx.lose)
	rl.UnloadSound(game_sfx.merge)
	rl.UnloadSound(game_sfx.select)
	rl.UnloadSound(game_sfx.win_round)
	rl.UnloadMusicStream(background_music)
	// rl.UnloadMusicStream(background_music_1)
	// rl.UnloadMusicStream(background_music_2)
	rl.CloseAudioDevice()
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
