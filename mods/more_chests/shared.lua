-- Load support for translation.
local S = minetest.get_translator("more_chests")

local function has_locked_chest_privilege(meta, player, pos)
	local name = player:get_player_name()
	local shared = " "..meta:get_string("shared").." "
	if name == meta:get_string("owner") then
		return true
	elseif shared:find(" "..name.." ") then
		return true
	elseif default.can_interact_with_node(player, pos) then
		return true
	else
		return false
	end
end

local function get_formspec(string)
	return "size[8,10]"..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..	
		"list[current_name;main;0,0.3;8,4;]"..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6;8,3;8]" ..
		"field[.25,9.5;8,1;shared;"..S("Shared with (separate names with spaces)")..":;"..string.."]"..
		"button[6,9.2;2,1;submit;"..S("submit").."]" ..
		"listring[current_name;main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0,4.85)
end

minetest.register_node("more_chests:shared", {
	description = S("Shared Chest"),
	tiles = {"shared_top.png", "shared_top.png", "shared_side.png",
		"shared_side.png", "shared_side.png", "shared_front.png"},
	paramtype2 = "facedir",
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2, tubedevice = 1, tubedevice_receiver = 1},
-- Pipeworks
	tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("main", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("main", stack)
		end,
		input_inventory = "main",
		connect_sides = {left = 1, right = 1, back = 1, front = 1, bottom = 1, top = 1}
	},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", S("@1 (owned by @2)",
				S("Shared Chest"),
				meta:get_string("owner")))
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_formspec(""))
		meta:set_string("infotext", S("Shared Chest"))
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_chest_privilege(meta, player, pos) then
			minetest.log("action", player:get_player_name()..
					" tried to access a shared chest belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return count
	end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_chest_privilege(meta, player, pos) then
			minetest.log("action", player:get_player_name()..
					" tried to access a shared chest belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return stack:get_count()
	end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_chest_privilege(meta, player, pos) then
			minetest.log("action", player:get_player_name()..
					" tried to access a shared chest belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return stack:get_count()
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff in shared chest at "..minetest.pos_to_string(pos))
	end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff to shared chest at "..minetest.pos_to_string(pos))
	end,
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" takes stuff from shared chest at "..minetest.pos_to_string(pos))
	end,
	on_receive_fields = function(pos, formspec, fields, sender)
		local meta = minetest.get_meta(pos);
		if fields.shared then 
			if meta:get_string("owner") == sender:get_player_name() then
				meta:set_string("shared", fields.shared);
				meta:set_string("formspec", get_formspec(fields.shared))
			end
		end
	end,
})

minetest.register_craft({
	output = 'more_chests:shared',
	recipe = {
		{'default:wood','default:leaves','default:wood'},
		{'default:wood','default:steel_ingot','default:wood'},
		{'default:wood','default:wood','default:wood'}
	}
})
