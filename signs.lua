local metro = font_api.get_font("metro")
metro.widths[8201] = 2 -- Thin Space ( )
metro.widths[8592] = 16 -- ←
metro.widths[8593] = 16 -- ↑
metro.widths[8594] = 16 -- →
metro.widths[8595] = 16 -- ↓
metro.widths[8596] = 16 -- ↔
metro.widths[8597] = 16 -- ↕
metro.widths[8598] = 16 -- ↖
metro.widths[8599] = 16 -- ↗
metro.widths[8600] = 16 -- ↘
metro.widths[8601] = 16 -- ↙
metro.widths[8624] = 16 -- ↰
metro.widths[8625] = 16 -- ↱

local rotation = { 12, 9, 18, 7, 13, 1, 15, 21, 17, 23, 19, 3, 20, 10, 2, 8, 0, 6, 22, 4, 16, 11, 14, 5 }

local palette_b = { "#ffffff", "#f6ce0b", "#e57200", "#df4661", "#c9eb00", "#3ddce1", "#e0aa0f", "#e2d6b5" }
local palette_w = { "#074389", "#b91422", "#623521", "#007a54", "#000000", "#383838", "#bc8f36", "#6d2077" }
local palette_t = { "#b91422", "#074389", "#623521", "#007a54", "#000000", "#383838", "#e57200", "#f6ce0b" }

local is_horizontal = function(param2)
    local p2 = param2 % 32
    return p2 == 4 or p2 == 6 or p2 == 8 or p2 == 10 or p2 == 13 or p2 == 15 or p2 == 17 or p2 == 19
end

local is_portrait = function(param2)
    local p2 = param2 % 32
    return p2 == 5 or p2 == 7 or p2 == 9 or p2 == 11 or p2 == 12 or p2 == 14 or p2 == 16 or p2 == 18
end

local on_display_update = function(pos, objref)
    local meta = minetest.get_meta(pos)
    local node = minetest.get_node(pos)
    local node_def = minetest.registered_nodes[node.name]
    local entity = objref:get_luaentity()

    if not entity or not node_def or not node_def.display_entities[entity.name] then
        return
    end

    local def = node_def.display_entities[entity.name]
    local p2 = node.param2
    local size_x = is_portrait(p2) and def.size.y or def.size.x
    local size_y = is_portrait(p2) and def.size.x or def.size.y

    if meta:get_string("use") == "image" then
        objref:set_properties({
            textures = { meta:get_string("image") },
            visual_size = {
                x = size_x - 1/8,
                y = size_y - 1/8,
            },
        })
    else
        local font = font_api.get_font("metro")
        local aspect_factor = 1.5

        -- Add thin space at the beginning of every line for better centering.
        local text, lines = meta:get_string("text"):gsub('\n', '\n ')
        text = " "..text
        lines = lines + 1

        local longest_line = 0
        for line in text:gmatch("([^\n]*)\n?") do
            local line_length = font:get_width(line)
            if line_length > longest_line then
                longest_line = line_length
            end
        end

        longest_line = longest_line / aspect_factor

        local height = font:get_height(lines)
        local width = height * size_x / size_y

        if longest_line > width then
            width = longest_line
            height = width * size_y / size_x
        end

        width = width * aspect_factor

        objref:set_properties({
            textures = {
                font:render(text, width, height, {
                    lines = lines,
                    halign = def.halign,
                    valign = def.valign,
                    color = def.color
                })
            },
            visual_size = {
                x = size_x - 1/8,
                y = size_y - 1/4,
            },
        })

    end
    if not is_horizontal(p2) then
        local r = objref:get_rotation()
        objref:set_rotation({
            x = (p2%32 == 14 or p2%32 == 18) and 0 or r.x,
            y = (p2%32 == 14 or p2%32 == 18) and math.pi or r.y,
            z = 0,
        })
    end

end

local registered_images = {}
local registered_image_ids = {}

streets.register_sign_image = function(id, def)
    registered_image_ids[#registered_image_ids+1] = id
    registered_images[id] = def
end

local get_library_formspec = function(format)
    local t = {}
    local ctr = 0
    for _, id in ipairs(registered_image_ids) do
        local def = registered_images[id]
        if def["image_"..format] then
            t[#t+1] = string.format(
                "image_button[%d,%d;.75,.75;%s;library_image_%s;]",
                ctr % 4,
                ctr / 4,
                minetest.formspec_escape(def.image),
                id
            )
            ctr = ctr + 1
        end
    end
    if ctr == 0 then
        return "textarea[0,0;4,5;;;There are no registered library images for this sign.]"
    end
    return table.concat(t)
end

local get_format = function(pos)
    local alias = {}
    alias["1to1_portrait"] = "1to1"
    alias["round_portrait"] = "round"

    local node = minetest.get_node(pos)
    local node_def = minetest.registered_nodes[node.name] or {}
    local format = node_def.sign_format..(is_portrait(node.param2) and "_portrait" or "")
    return alias[format] or format
end

local set_formspec = function(pos)
    local meta = minetest.get_meta(pos)
    local image = meta:get_string("image")
    local text = meta:get_string("text")
    local header = table.concat({
        "formspec_version[4]",
        "size[5,8]",
        "position[.1,.5]",
        "anchor[0,.5]",
        "box[0,0;5,.5;#fff]",
        "label[.25,.25;"..minetest.colorize("black", "SIGN EDITOR").."]",
    })

    local body = table.concat(meta:get_string("show") == "image_library" and {
        "button[3,.75;1.75,.75;close_library;Close]",
        "scrollbar[4.5,1.75;.25,6;vertical;scrollbar;0]",
        "scroll_container[.25,1.75;4.25,6;scrollbar;vertical]",
        get_library_formspec(get_format(pos)),
        "scroll_container_end[]"
    } or {
        "textarea[.25,1;4.5,1.5;text;Text:;"..minetest.formspec_escape(text).."]",
        "button[3,3.5;1.75,.75;save_text;Save]",
        "box[.25,5;2,.01;#fff]",
        "label[2.25,5; OR ]",
        "box[2.75,5;2,.01;#fff]",
        "field[.25,5.5;4.5,.75;image;Image:;"..minetest.formspec_escape(image).."]",
        "field_close_on_enter[image;false]",
        "button[.25,6.5;1.75,.75;image_library;Library]",
        "button[3,6.5;1.75,.75;save_image;Save]",
    })

    meta:set_string("formspec", header..body)
end

local on_receive_fields = function(pos, formname, fields, sender)
    if not minetest.is_protected(pos, sender:get_player_name()) then
        local meta = minetest.get_meta(pos)
        if fields.save_text then
            meta:set_string("text", fields.text)
            meta:set_string("use", "text")
        elseif fields.save_image then
            meta:set_string("image", fields.image)
            meta:set_string("use", "image")
        elseif fields.image_library then
            meta:set_string("show", "image_library")
        elseif fields.close_library then
            meta:set_string("show", "")
        else
            for _,id in ipairs(registered_image_ids) do
                if fields["library_image_"..id] then
                    local def = registered_images[id]
                    local node = minetest.get_node(pos)
                    local node_def = minetest.registered_nodes[node.name] or {}
                    local image = is_portrait(node.param2) and def["image_"..node_def.sign_format.."_portrait"] or def["image_"..node_def.sign_format] or def.image
                    if not def.do_not_color then
                        image = image.."^[colorize:"..(node_def.display_entities["signs:display_text"].color or "#000")
                    end
                    meta:set_string("image", image)
                    meta:set_string("use", "image")
                end
            end
        end
    end
    set_formspec(pos)
    display_api.update_entities(pos)
end

streets.register_sign_image("danger", {
    image = "[combine:18x18:8,3=font_metro_0021.png",
    image_1to1 = "[combine:18x18:8,3=font_metro_0021.png",
    image_round = "[combine:18x18:8,3=font_metro_0021.png",
    image_diamond = "[combine:18x18:8,3=font_metro_0021.png",
    image_triangle = "[combine:22x20:10,5=font_metro_0021.png",
    image_4to3 = "[combine:24x18:11,3=font_metro_0021.png",
    image_4to3_portrait = "[combine:18x24:8,6=font_metro_0021.png",
    image_arrow = "[combine:54x18:26,3=font_metro_0021.png",
    image_arrow_portrait = "[combine:18x54:8,21=font_metro_0021.png",
})

streets.register_sign_image("roadwork", {
    image = "[combine:130x130:25,28=streets_sign_roadwork.png",
    image_1to1 = "[combine:90x90:5,13=streets_sign_roadwork.png",
    image_diamond = "[combine:130x130:25,25=streets_sign_roadwork.png",
    image_triangle = "[combine:152x132:43,50=streets_sign_roadwork.png",
    image_4to3 = "[combine:110x80:15,8=streets_sign_roadwork.png",
    image_4to3_portrait = "[combine:90x124:5,30=streets_sign_roadwork.png",
    image_arrow = "[combine:270x90:95,13=streets_sign_roadwork.png",
    image_arrow_portrait = "[combine:90x270:5,103=streets_sign_roadwork.png",
})

streets.register_sign_image("ice", {
    image = "[combine:90x90:25,21=streets_sign_ice.png",
    image_1to1 = "[combine:90x90:25,21=streets_sign_ice.png",
    image_round = "[combine:90x90:25,21=streets_sign_ice.png",
    image_diamond = "[combine:90x90:25,21=streets_sign_ice.png",
    image_triangle = "[combine:122x104:41,44=streets_sign_ice.png",
    image_4to3 = "[combine:88x66:24,10=streets_sign_ice.png",
    image_4to3_portrait = "[combine:66x88:13,21=streets_sign_ice.png",
})

streets.register_sign_image("narrow", {
    image = "[combine:32x32:10,8=streets_sign_narrow.png",
    image_1to1 = "[combine:32x32:10,8=streets_sign_narrow.png",
    image_diamond = "[combine:32x32:10,8=streets_sign_narrow.png",
    image_triangle = "[combine:40x34:14,12=streets_sign_narrow.png",
})

streets.register_sign_image("narrow_right", {
    image = "[combine:32x32:10,8=streets_sign_narrow_right.png",
    image_1to1 = "[combine:32x32:10,8=streets_sign_narrow_right.png",
    image_diamond = "[combine:32x32:10,8=streets_sign_narrow_right.png",
    image_triangle = "[combine:40x34:14,12=streets_sign_narrow_right.png",
})

streets.register_sign_image("narrow_left", {
    image = "[combine:32x32:10,8=streets_sign_narrow_right.png\\^[transformFX",
    image_1to1 = "[combine:32x32:10,8=streets_sign_narrow_right.png\\^[transformFX",
    image_diamond = "[combine:32x32:10,8=streets_sign_narrow_right.png\\^[transformFX",
    image_triangle = "[combine:40x34:14,12=streets_sign_narrow_right.png\\^[transformFX",
})

streets.register_sign_image("curve_right", {
    image = "[combine:32x32:10,8=streets_sign_curve_right.png",
    image_1to1 = "[combine:32x32:10,8=streets_sign_curve_right.png",
    image_diamond = "[combine:32x32:10,8=streets_sign_curve_right.png",
    image_triangle = "[combine:40x34:14,12=streets_sign_curve_right.png",
})

streets.register_sign_image("curve_left", {
    image = "[combine:32x32:10,8=streets_sign_curve_right.png\\^[transformFX",
    image_1to1 = "[combine:32x32:10,8=streets_sign_curve_right.png\\^[transformFX",
    image_diamond = "[combine:32x32:10,8=streets_sign_curve_right.png\\^[transformFX",
    image_triangle = "[combine:40x34:14,12=streets_sign_curve_right.png\\^[transformFX",
})

streets.register_sign_image("hill", {
    image = "[combine:32x32:6,9=streets_sign_hill.png",
    image_diamond = "[combine:32x32:6,9=streets_sign_hill.png",
    image_triangle = "[combine:34x28:7,14=streets_sign_hill.png",
})

streets.register_sign_image("slope", {
    image = "[combine:32x32:6,9=streets_sign_hill.png\\^[transformFX",
    image_diamond = "[combine:32x32:6,9=streets_sign_hill.png\\^[transformFX",
    image_triangle = "[combine:34x28:7,14=streets_sign_hill.png\\^[transformFX",
})

streets.register_sign_image("traffic_lights", {
    image = "[combine:32x32:10,8=streets_sign_traffic_lights.png",
    image_1to1 = "[combine:32x32:10,8=streets_sign_traffic_lights.png",
    image_diamond = "[combine:32x32:10,8=streets_sign_traffic_lights.png",
    image_triangle = "[combine:40x34:14,12=streets_sign_traffic_lights.png",
    do_not_color = true,
})

streets.register_sign_image("two_way_traffic", {
    image = "[combine:32x32:4,10=font_metro_2193.png:14,9=font_metro_2191.png",
    image_1to1 = "[combine:24x24:0,6=font_metro_2193.png:10,5=font_metro_2191.png",
    image_round = "[combine:32x32:4,10=font_metro_2193.png:14,9=font_metro_2191.png",
    image_diamond = "[combine:32x32:4,10=font_metro_2193.png:14,9=font_metro_2191.png",
    image_triangle = "[combine:44x36:10,18=font_metro_2193.png:18,18=font_metro_2191.png",
})

streets.register_sign_image("oncoming_give_way", {
    image = "[combine:32x32:4,10=font_metro_2193.png:14,9=font_metro_2191.png\\^[colorize\\:"..palette_t[1],
    image_1to1 = "[combine:24x24:0,6=font_metro_2193.png:10,5=font_metro_2191.png\\^[colorize\\:"..palette_t[1],
    image_round = "[combine:32x32:4,10=font_metro_2193.png:14,9=font_metro_2191.png\\^[colorize\\:"..palette_t[1],
    image_diamond = "[combine:32x32:4,10=font_metro_2193.png:14,9=font_metro_2191.png\\^[colorize\\:"..palette_t[1],
    image_triangle = "[combine:44x36:10,18=font_metro_2193.png:18,18=font_metro_2191.png\\^[colorize\\:"..palette_t[1],
    do_not_color = true,
})

streets.register_sign_image("priority_over_oncoming", {
    image = "[combine:32x32:4,10=font_metro_2193.png\\^[colorize\\:"..palette_t[1]..":14,9=font_metro_2191.png\\^[colorize\\:#fff",
    image_1to1 = "[combine:24x24:0,6=font_metro_2193.png\\^[colorize\\:"..palette_t[1]..":10,5=font_metro_2191.png\\^[colorize\\:#fff",
    image_round = "[combine:32x32:4,10=font_metro_2193.png\\^[colorize\\:"..palette_t[1]..":14,9=font_metro_2191.png\\^[colorize\\:#fff",
    image_diamond = "[combine:32x32:4,10=font_metro_2193.png\\^[colorize\\:"..palette_t[1]..":14,9=font_metro_2191.png\\^[colorize\\:#fff",
    image_triangle = "[combine:44x36:10,18=font_metro_2193.png\\^[colorize\\:"..palette_t[1]..":18,18=font_metro_2191.png\\^[colorize\\:#fff",
    do_not_color = true,
})

streets.register_sign_image("priority", {
    image = "[combine:32x32:10,8=streets_sign_intersection_priority.png",
    image_1to1 = "[combine:32x32:10,8=streets_sign_intersection_priority.png",
    image_diamond = "[combine:32x32:10,8=streets_sign_intersection_priority.png",
    image_triangle = "[combine:40x34:14,12=streets_sign_intersection_priority.png",
})

streets.register_sign_image("crossing", {
    image = "[combine:18x17:5,1=font_metro_00d7.png",
    image_diamond = "[combine:18x17:5,1=font_metro_00d7.png",
    image_triangle = "[combine:24x20:8,6=font_metro_00d7.png",
})

streets.register_sign_image("radiation", {
    image = "[combine:48x48:4,5=streets_sign_radiation.png",
    image_triangle = "[combine:108x92:34,42=streets_sign_radiation.png",
})

streets.register_sign_image("electricity", {
    image = "[combine:104x104:33,4=streets_sign_electricity.png",
    image_triangle = "[combine:192x164:72,45=streets_sign_electricity.png",
})

streets.register_sign_image("limits_end", {
    image = "streets_sign_limits_end.png",
    image_round = "streets_sign_limits_end.png",
})

streets.register_sign_image("no_parking", {
    image = "streets_sign_no_parking.png",
    image_round = "streets_sign_no_parking.png",
    do_not_color = true,
})

streets.register_sign_image("no_halting", {
    image = "streets_sign_no_halting.png",
    image_round = "streets_sign_no_halting.png",
    do_not_color = true,
})

streets.register_sign_image("no_passing", {
    image = "streets_sign_no_passing.png",
    image_round = "streets_sign_no_passing.png",
    do_not_color = true,
})

streets.register_sign_image("no_passing_truck", {
    image = "streets_sign_no_passing_truck.png",
    image_round = "streets_sign_no_passing_truck.png",
    do_not_color = true,
})

streets.register_sign_image("bar", {
    image = "streets_sign_bar.png",
    image_round = "streets_sign_bar.png",
})

streets.register_sign_image("pedestrian", {
    image = "[combine:90x90:28,13=streets_sign_pedestrian.png",
    image_1to1 = "[combine:90x90:28,13=streets_sign_pedestrian.png",
    image_round = "[combine:90x90:28,13=streets_sign_pedestrian.png",
    image_diamond = "[combine:90x90:28,10=streets_sign_pedestrian.png",
    image_triangle = "[combine:122x104:44,28=streets_sign_pedestrian.png",
    image_4to3 = "[combine:88x66:27,2=streets_sign_pedestrian.png",
    image_4to3_portrait = "[combine:66x88:16,13=streets_sign_pedestrian.png",
    image_arrow = "[combine:270x90:118,13=streets_sign_pedestrian.png",
    image_arrow_portrait = "[combine:90x270:28,103=streets_sign_pedestrian.png",
})

streets.register_sign_image("car", {
    image = "[combine:90x90:21,26=streets_sign_car.png",
    image_1to1 = "[combine:90x90:21,26=streets_sign_car.png",
    image_round = "[combine:90x90:21,26=streets_sign_car.png",
    image_diamond = "[combine:90x90:21,26=streets_sign_car.png",
    image_triangle = "[combine:122x104:37,50=streets_sign_car.png",
    image_4to3 = "[combine:88x66:20,15=streets_sign_car.png",
    image_4to3_portrait = "[combine:66x88:9,26=streets_sign_car.png",
    image_arrow = "[combine:270x90:111,26=streets_sign_car.png",
    image_arrow_portrait = "[combine:90x270:21,116=streets_sign_car.png",
})

streets.register_sign_image("truck", {
    image = "[combine:80x80:17,28=streets_sign_truck.png",
    image_1to1 = "[combine:80x80:17,28=streets_sign_truck.png",
    image_round = "[combine:80x80:17,28=streets_sign_truck.png",
    image_diamond = "[combine:80x80:17,28=streets_sign_truck.png",
    image_triangle = "[combine:108x92:29,55=streets_sign_truck.png",
    image_4to3 = "[combine:80x60:17,18=streets_sign_truck.png",
    image_4to3_portrait = "[combine:66x88:10,32=streets_sign_truck.png",
    image_arrow = "[combine:135x45:43,10=streets_sign_truck.png",
    image_arrow_portrait = "[combine:50x150:2,63=streets_sign_truck.png",
})

streets.register_sign_image("parking", {
    image = "[combine:22x22:7,5=font_metro_0050.png",
    image_1to1 = "[combine:18x18:5,3=font_metro_0050.png",
    image_4to3 = "[combine:24x18:8,3=font_metro_0050.png",
    image_4to3_portrait = "[combine:18x24:5,6=font_metro_0050.png",
    image_arrow = "[combine:54x18:23,3=font_metro_0050.png",
    image_arrow_portrait = "[combine:18x54:5,21=font_metro_0050.png",
})

streets.register_sign_image("priority_road", {
    image = "streets_sign_priority_road.png",
    image_diamond = "streets_sign_priority_road.png",
    do_not_color = true,
})

streets.register_sign_image("priority_road_end", {
    image = "streets_sign_priority_road_end.png",
    image_diamond = "streets_sign_priority_road_end.png",
    do_not_color = true,
})

streets.register_sign_image("dead_end", {
    image = "streets_sign_dead_end.png",
    image_1to1 = "streets_sign_dead_end.png",
    do_not_color = true,
})

streets.register_sign_image("cross", {
    image = "[combine:10x10:2,-2=font_metro_002b.png",
    image_1to1 = "[combine:10x10:2,-2=font_metro_002b.png",
})

streets.register_sign_image("red_cross", {
    image = "[combine:10x10:2,-2=font_metro_002b.png^[colorize:"..palette_t[1],
    image_1to1 = "[combine:10x10:2,-2=font_metro_002b.png^[colorize:"..palette_t[1],
    do_not_color = true,
})

streets.register_sign_image("chevron_right", {
    image = "streets_sign_chevron_right.png",
    image_1to1 = "streets_sign_chevron_right.png",
    do_not_color = true,
})

streets.register_sign_image("chevron_left", {
    image = "streets_sign_chevron_right.png^[transformFX",
    image_1to1 = "streets_sign_chevron_right.png^[transformFX",
    do_not_color = true,
})

streets.register_sign_image("guide_right", {
    image = "streets_sign_guide_right.png",
    image_4to3_portrait = "streets_sign_guide_right.png",
    do_not_color = true,
})

streets.register_sign_image("guide_left", {
    image = "streets_sign_guide_right.png^[transformFX",
    image_4to3_portrait = "streets_sign_guide_right.png^[transformFX",
    do_not_color = true,
})

streets.register_sign_image("divider", {
    image = "streets_sign_divider.png",
    image_4to3_portrait = "streets_sign_divider.png",
    do_not_color = true,
})

streets.register_sign_image("turn_right", {
    image = "[combine:24x24:5,4=font_metro_21b1.png",
    image_1to1 = "[combine:24x24:5,4=font_metro_21b1.png",
    image_round = "[combine:24x24:5,4=font_metro_21b1.png",
    image_diamond = "[combine:24x24:5,4=font_metro_21b1.png",
    image_4to3 = "[combine:24x24:5,4=font_metro_21b1.png",
    image_4to3_portrait = "[combine:24x24:5,4=font_metro_21b1.png",
})

streets.register_sign_image("turn_left", {
    image = "[combine:24x24:4,4=font_metro_21b0.png",
    image_1to1 = "[combine:24x24:4,4=font_metro_21b0.png",
    image_round = "[combine:24x24:4,4=font_metro_21b0.png",
    image_diamond = "[combine:24x24:4,4=font_metro_21b0.png",
    image_4to3 = "[combine:24x24:4,4=font_metro_21b0.png",
    image_4to3_portrait = "[combine:24x24:4,4=font_metro_21b0.png",
})

streets.register_sign_image("right", {
    image = "[combine:23x24:4,5=font_metro_2192.png",
    image_1to1 = "[combine:23x24:4,5=font_metro_2192.png",
    image_round = "[combine:23x24:4,5=font_metro_2192.png",
    image_diamond = "[combine:23x24:4,5=font_metro_2192.png",
    image_4to3 = "[combine:23x24:4,5=font_metro_2192.png",
    image_4to3_portrait = "[combine:23x24:4,5=font_metro_2192.png",
})

streets.register_sign_image("left", {
    image = "[combine:23x24:4,5=font_metro_2190.png",
    image_1to1 = "[combine:23x24:4,5=font_metro_2190.png",
    image_round = "[combine:23x24:4,5=font_metro_2190.png",
    image_diamond = "[combine:23x24:4,5=font_metro_2190.png",
    image_4to3 = "[combine:23x24:4,5=font_metro_2190.png",
    image_4to3_portrait = "[combine:23x24:4,5=font_metro_2190.png",
})

streets.register_sign_image("straight", {
    image = "[combine:24x24:5,5=font_metro_2191.png",
    image_1to1 = "[combine:24x24:5,5=font_metro_2191.png",
    image_round = "[combine:24x24:5,5=font_metro_2191.png",
    image_diamond = "[combine:24x24:5,5=font_metro_2191.png",
    image_4to3 = "[combine:24x24:5,5=font_metro_2191.png",
    image_4to3_portrait = "[combine:24x24:5,5=font_metro_2191.png",
})

streets.register_sign_image("straight_right", {
    image = "[combine:30x30:8,5=font_metro_2191.png:11,10=font_metro_21b1.png",
    image_1to1 = "[combine:30x30:8,5=font_metro_2191.png:11,10=font_metro_21b1.png",
    image_round = "[combine:30x30:8,5=font_metro_2191.png:11,10=font_metro_21b1.png",
    image_diamond = "[combine:30x30:8,5=font_metro_2191.png:11,10=font_metro_21b1.png",
    image_4to3 = "[combine:30x30:8,5=font_metro_2191.png:11,10=font_metro_21b1.png",
    image_4to3_portrait = "[combine:30x30:8,5=font_metro_2191.png:11,10=font_metro_21b1.png",
})

streets.register_sign_image("straight_left", {
    image = "[combine:30x30:8,5=font_metro_2191.png:4,10=font_metro_21b0.png",
    image_1to1 = "[combine:30x30:8,5=font_metro_2191.png:4,10=font_metro_21b0.png",
    image_round = "[combine:30x30:8,5=font_metro_2191.png:4,10=font_metro_21b0.png",
    image_diamond = "[combine:30x30:8,5=font_metro_2191.png:4,10=font_metro_21b0.png",
    image_4to3 = "[combine:30x30:8,5=font_metro_2191.png:4,10=font_metro_21b0.png",
    image_4to3_portrait = "[combine:30x30:8,5=font_metro_2191.png:4,10=font_metro_21b0.png",
})

streets.register_sign_image("turn", {
    image = "[combine:30x30:11,9=font_metro_21b1.png:4,9=font_metro_21b0.png",
    image_1to1 = "[combine:30x30:11,9=font_metro_21b1.png:4,9=font_metro_21b0.png",
    image_round = "[combine:30x30:11,9=font_metro_21b1.png:4,9=font_metro_21b0.png",
    image_diamond = "[combine:30x30:11,9=font_metro_21b1.png:4,9=font_metro_21b0.png",
    image_4to3 = "[combine:30x30:11,9=font_metro_21b1.png:4,9=font_metro_21b0.png",
    image_4to3_portrait = "[combine:30x30:11,9=font_metro_21b1.png:4,9=font_metro_21b0.png",
})

streets.register_sign_image("roundabout", {
    image = "[combine:80x80:10,10=streets_sign_roundabout.png",
    image_triangle = "[combine:152x132:46,55=streets_sign_roundabout.png",
    image_1to1 = "[combine:80x80:10,10=streets_sign_roundabout.png",
    image_round = "[combine:80x80:10,10=streets_sign_roundabout.png",
    image_diamond = "[combine:88x88:14,14=streets_sign_roundabout.png",
    image_4to3 = "[combine:88x66:14,3=streets_sign_roundabout.png",
    image_4to3_portrait = "[combine:66x88:3,14=streets_sign_roundabout.png",
})

streets.register_sign_image("pass_right", {
    image = "[combine:26x26:6,6=font_metro_2198.png",
    image_1to1 = "[combine:26x26:6,6=font_metro_2198.png",
    image_round = "[combine:26x26:6,6=font_metro_2198.png",
    image_diamond = "[combine:26x26:6,6=font_metro_2198.png",
    image_4to3 = "[combine:26x26:6,6=font_metro_2198.png",
    image_4to3_portrait = "[combine:26x26:6,6=font_metro_2198.png",
})

streets.register_sign_image("pass_left", {
    image = "[combine:26x26:5,6=font_metro_2199.png",
    image_1to1 = "[combine:26x26:5,6=font_metro_2199.png",
    image_round = "[combine:26x26:5,6=font_metro_2199.png",
    image_diamond = "[combine:26x26:5,6=font_metro_2199.png",
    image_4to3 = "[combine:26x26:5,6=font_metro_2199.png",
    image_4to3_portrait = "[combine:26x26:5,6=font_metro_2199.png",
})

streets.register_sign_image("pedestrians_left", {
    image = "[combine:96x72:5,13=font_metro_2190.png\\^[resize\\:48x45:55,5=streets_sign_pedestrian.png",
    image_4to3 = "[combine:96x72:5,13=font_metro_2190.png\\^[resize\\:48x45:55,5=streets_sign_pedestrian.png",
})

streets.register_sign_image("pedestrians_right", {
    image = "[combine:96x72:5,13=font_metro_2190.png\\^[resize\\:48x45:55,5=streets_sign_pedestrian.png^[transformFX",
    image_4to3 = "[combine:96x72:5,13=font_metro_2190.png\\^[resize\\:48x45:55,5=streets_sign_pedestrian.png^[transformFX",
})

for i=0,3 do
    streets.register_sign_image("priority_turn_a"..i, {
        image = "streets_sign_priority_turn_a.png^[transform"..i,
        image_1to1 = "streets_sign_priority_turn_a.png^[transform"..i,
        image_4to3 = "[combine:38x28:5,0=streets_sign_priority_turn_a.png\\^[transform"..i,
        image_diamond = "[combine:32x32:2,2=streets_sign_priority_turn_a.png^[transform"..i,
    })
    streets.register_sign_image("priority_turn_b"..i, {
        image = "streets_sign_priority_turn_b.png^[transform"..i,
        image_1to1 = "streets_sign_priority_turn_b.png^[transform"..i,
        image_4to3 = "[combine:38x28:5,0=streets_sign_priority_turn_b.png\\^[transform"..i,
        image_diamond = "[combine:32x32:2,2=streets_sign_priority_turn_b.png^[transform"..i,
    })
    streets.register_sign_image("priority_turn_c"..i, {
        image = "streets_sign_priority_turn_c.png^[transform"..i,
        image_1to1 = "streets_sign_priority_turn_c.png^[transform"..i,
        image_4to3 = "[combine:38x28:5,0=streets_sign_priority_turn_c.png\\^[transform"..i,
        image_diamond = "[combine:32x32:2,2=streets_sign_priority_turn_c.png^[transform"..i,
    })
end

streets.register_sign = function(name, def)
    local register = function(base_name, base_def)
        local polemount_def = table.copy(base_def)
        polemount_def.mesh = "streets_sign_polemount.obj"
        polemount_def.display_entities["signs:display_text"].depth = polemount_def.display_entities["signs:display_text"].depth + 3/8
        polemount_def.selection_box.fixed[3] = polemount_def.selection_box.fixed[3] + 3/8
        polemount_def.selection_box.fixed[6] = polemount_def.selection_box.fixed[6] + 3/8
        polemount_def.collision_box.fixed[3] = polemount_def.collision_box.fixed[3] + 3/8
        polemount_def.collision_box.fixed[6] = polemount_def.collision_box.fixed[6] + 3/8
        polemount_def.groups.not_in_creative_inventory = 1
        polemount_def.drops = base_name

        minetest.register_node(base_name, base_def)
        minetest.register_node(base_name.."_polemount", polemount_def)
    end

    def.use_texture_alpha = "clip"
    def.paramtype = "light"
    def.paramtype2 = "colorfacedir"
    def.drawtype = "mesh"
    def.mesh = "streets_sign.obj"
    def.sunlight_propagates = true
    def.groups = { snappy = 3, level = 1 }
    def.groups["streets_sign_"..name] = 1
    def.selection_box = {
        type = "fixed",
        fixed = { def.box[1], def.box[2], 11/32, def.box[3], def.box[4], 7/16 },
    }
    def.collision_box = {
        type = "fixed",
        fixed = { def.box[1], def.box[2], 11/32, def.box[3], def.box[4], 7/16 },
    }
    def.preserve_metadata = function(pos, oldnode, oldmeta, drops)
        for _,drop in ipairs(drops) do
            local meta = drop:get_meta()
            if meta:get_int("palette_index") == 0 then
                meta:set_string("palette_index", "")
            end
            drop:set_name(drop:get_name():gsub("_polemount", ""))
        end
    end
    def.display_entities = {
        ["signs:display_text"] = {
            on_display_update = on_display_update,
            depth = display_api.entity_spacing + 3/8 - .01,
            size = { x = def.box[3] - def.box[1], y = def.box[4] - def.box[2] },
        },

    }
    def.on_place = display_api.on_place
    def.on_construct = 	function(pos)
        set_formspec(pos)
        display_api.on_construct(pos)
    end
    def.on_destruct = display_api.on_destruct
    def.on_rotate = function(pos, node, user, mode, new_param2)
        node.param2 = math.floor(node.param2/32)*32 + rotation[node.param2%32 + 1]
        minetest.swap_node(pos, node)
        display_api.update_entities(pos)
        return true
    end
    def.on_receive_fields = on_receive_fields
    def.on_punch = function(pos, node, player, pointed_thing)
        set_formspec(pos)
        display_api.update_entities(pos)
    end
    def.after_place_node = function(pos, placer, _, pointed_thing)
        if placer and placer:is_player() then
            local eye_pos = placer:get_pos()
            eye_pos.y = eye_pos.y + placer:get_properties().eye_height + placer:get_eye_offset().y / 10
            local raycast = minetest.raycast(eye_pos, vector.add(eye_pos, vector.multiply(placer:get_look_dir(), 12)), false)
            raycast:next()
            local exact_point = (raycast:next() or {}).intersection_point
            local node = minetest.get_node(pos)
            local behind_pos = table.copy(pos)
            local param2 = node.param2 % 32
            if (param2 >= 0 and param2 <= 4)  and exact_point then
                local component = (param2 == 0 or param2 == 2) and "z" or "x"
                behind_pos[component] = behind_pos[component] + (param2 <= 1 and 1 or -1)
                local is_pole = string.sub(node.name, #node.name - 10, #node.name)
                if math.abs(pos[component] - exact_point[component]) >= .75 and is_pole ~= "_polemount" then
                    node.name = node.name .. "_polemount"
                    minetest.set_node(pos, node)
                end
            end
        end
    end

    local def_b = table.copy(def)
    def_b.color = palette_b[1]
    def_b.palette = "streets_signs_palette_b.png"
    def_b.tiles = {
        { name = "streets_base.png", color = "white" },
        { name = "streets_base.png", color = "white" },
        def.texture,
        { name = def.texture.."^[colorize:#555", color = "white" },
    }
    def_b.overlay_tiles = {
        "",
        "",
        { name = def.overlay_black, color = "white" },
        "",
    }
    register("streets:sign_"..name.."_b", def_b)

    for idx, color in ipairs({ "white", "yellow", "orange", "magenta", "green", "cyan", "dark_green", "grey" }) do
        minetest.register_craft({
            output = idx == 1 and "streets:sign_"..name.."_b" or minetest.itemstring_with_palette("streets:sign_"..name.."_b", (idx-1)*32),
            type = "shapeless",
            recipe = {"group:streets_sign_"..name, "dye:black", "dye:"..color, "dye:"..color, }
        })
    end

    local def_w = table.copy(def)
    def_w.color = palette_w[1]
    def_w.palette = "streets_signs_palette_w.png"
    def_w.tiles = {
        { name = "streets_base.png", color = "white" },
        { name = "streets_base.png", color = "white" },
        def.texture,
        { name = def.texture.."^[colorize:#555", color = "white" },
    }
    def_w.overlay_tiles = {
        "",
        "",
        { name = def.overlay_white, color = "white" },
        "",
    }
    def_w.display_entities["signs:display_text"].color = "#fff"
    register("streets:sign_"..name.."_w", def_w)

    for idx, color in ipairs({ "blue", "red", "brown", "dark_green", "black", "dark_grey", "yellow", "violet" }) do
        minetest.register_craft({
            output = idx == 1 and "streets:sign_"..name.."_w" or minetest.itemstring_with_palette("streets:sign_"..name.."_w", (idx-1)*32),
            type = "shapeless",
            recipe = {"group:streets_sign_"..name, "dye:white", "dye:"..color, "dye:"..color, }
        })
    end

    if def.overlay_thick then
        local def_t = table.copy(def)
        def_t.color = palette_t[1]
        def_t.palette = "streets_signs_palette_t.png"
        def_t.tiles = {
            { name = "streets_base.png", color = "white" },
            { name = "streets_base.png", color = "white" },
            { name = def.texture, color = "white" },
            { name = def.texture.."^[colorize:#555", color = "white" },
        }
        def_t.overlay_tiles = {
            "",
            "",
            def.overlay_thick,
            "",
        }
        register("streets:sign_"..name.."_t", def_t)

        for idx, color in ipairs({ "red", "blue", "brown", "dark_green", "black", "dark_grey", "orange", "yellow" }) do
            minetest.register_craft({
                output = idx == 1 and "streets:sign_"..name.."_t" or minetest.itemstring_with_palette("streets:sign_"..name.."_t", (idx-1)*32),
                type = "shapeless",
                recipe = {"group:streets_sign_"..name, "dye:white", "dye:"..color}
            })
        end
    end
end

local s = "default:sign_wall_steel"
local b = ""

streets.register_sign("large", {
    description = "Large Sign",
    texture = "streets_sign_large.png",
    overlay_black = "streets_sign_large_b.png",
    overlay_white = "streets_sign_large_w.png",
    box = {-1, -.75, 1, .75},
    sign_format = "4to3",
})

minetest.register_craft({
    output = "streets:sign_large_b",
    recipe = {
        {s, s, s,},
        {s, s, s,},
        {s, s, s,},
    }
})

streets.register_sign("medium", {
    description = "Medium Sign",
    texture = "streets_sign_medium.png",
    overlay_black = "streets_sign_medium_b.png",
    overlay_white = "streets_sign_medium_w.png",
    box = {-.75, -.5, .75, .5},
    sign_format = "4to3",
})

minetest.register_craft({
    output = "streets:sign_medium_b",
    recipe = {
        {s, s, s,},
        {s, s, s,},
    }
})

streets.register_sign("small", {
    description = "Small Sign",
    texture = "streets_sign_small.png",
    overlay_black = "streets_sign_small_b.png",
    overlay_white = "streets_sign_small_w.png",
    box = {-.5, -.375, .5, .375},
    sign_format = "4to3",
})

minetest.register_craft({
    output = "streets:sign_small_b",
    recipe = {
        {s, s,},
    }
})

streets.register_sign("arrow", {
    description = "Arrow Sign",
    texture = "streets_sign_arrow.png",
    overlay_black = "streets_sign_arrow_b.png",
    overlay_white = "streets_sign_arrow_w.png",
    box = {-.875, -11/32, 1, 11/32},
    sign_format = "arrow",
})

minetest.register_craft({
    output = "streets:sign_arrow_b",
    recipe = {
        {s, b,},
        {b, s,},
        {s, b,},
    }
})

streets.register_sign("diamond", {
    description = "Diamond Sign",
    texture = "streets_sign_diamond.png",
    overlay_black = "streets_sign_diamond_b.png",
    overlay_white = "streets_sign_diamond_w.png",
    box = {-19/32, -19/32, 19/32, 19/32},
    sign_format = "diamond",
})

minetest.register_craft({
    output = "streets:sign_diamond_b",
    recipe = {
        {b, s, b,},
        {s, b, s,},
        {b, s, b,},
    }
})

streets.register_sign("triangle", {
    description = "Triangle Sign",
    texture = "streets_sign_triangle.png",
    overlay_black = "streets_sign_triangle_b.png",
    overlay_white = "streets_sign_triangle_w.png",
    overlay_thick = "streets_sign_triangle_t.png",
    box = {-19/32, -.5, 19/32, 17/32},
    sign_format = "triangle",
})

minetest.register_craft({
    output = "streets:sign_triangle_b 2",
    recipe = {
        {b, s, b,},
        {s, b, s,},
        {s, s, s,},
    }
})

streets.register_sign("round", {
    description = "Round Sign",
    texture = "streets_sign_round.png",
    overlay_black = "streets_sign_round_b.png",
    overlay_white = "streets_sign_round_w.png",
    overlay_thick = "streets_sign_round_t.png",
    box = {-.5, -.5, .5, .5},
    sign_format = "round",
})

minetest.register_craft({
    output = "streets:sign_round_b 2",
    recipe = {
        {s, s, s,},
        {s, b, s,},
        {s, s, s,},
    }
})

streets.register_sign("square", {
    description = "Square Sign",
    texture = "streets_sign_square.png",
    overlay_black = "streets_sign_square_b.png",
    overlay_white = "streets_sign_square_w.png",
    overlay_thick = "streets_sign_square_t.png",
    box = {-.5, -.5, .5, .5},
    sign_format = "1to1",
})

minetest.register_craft({
    output = "streets:sign_square_b",
    recipe = {
        {s, s,},
        {s, s,},
    }
})

streets.register_sign("octagon", {
    description = "Octagon Sign",
    texture = "streets_sign_octagon.png",
    overlay_black = "streets_sign_octagon_b.png",
    overlay_white = "streets_sign_octagon_w.png",
    box = {-19/32, -19/32, 19/32, 19/32},
    sign_format = "octagon",
})

minetest.register_craft({
    output = "streets:sign_octagon_b",
    recipe = {
        {b, s, b,},
        {s, s, s,},
        {b, s, b,},
    }
})