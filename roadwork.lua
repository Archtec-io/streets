minetest.register_node("streets:roadwork_barrier_tape", {
    description = "Barrier Tape",
    paramtype = "light",
    drawtype = "nodebox",
    tiles = { "streets_roadwork_barrier_tape.png" },
    sunlight_propagates = true,
    use_texture_alpha = "clip",
    groups = { choppy = 3, dig_immediate = 3, level = 1, wall = 1 },
    node_box = {
        type = "connected",
        fixed = { -1 / 16, -0.5, -1 / 16, 1 / 16, 0.5, 1 / 16 },
        connect_front = { 0, 4 / 16, -0.5, 0, 6 / 16, 0 }, -- z-
        connect_back = { 0, 4 / 16, 0, 0, 6 / 16, 0.5 }, -- z+
        connect_left = { -0.5, 4 / 16, 0, 0, 6 / 16, 0 }, -- x-
        connect_right = { 0, 4 / 16, 0, 0.5, 6 / 16, 0 }, -- x+
    },
    selection_box = {
        type = "fixed",
        fixed = { -2 / 16, -0.5, -2 / 16, 2 / 16, 0.5, 2 / 16 },
    },
    connects_to = { "group:wall", "group:stone", "group:wood", "group:tree", "group:concrete" },
})

minetest.register_craft({
    output = "streets:roadwork_barrier_tape 24",
    recipe = {
        { "dye:red", "dye:white", "dye:red" },
        { "farming:string", "default:stick", "farming:string" },
        { "", "default:stick", "" }
    }
})

minetest.register_node("streets:roadwork_traffic_cone", {
    description = "Traffic Cone",
    paramtype = "light",
    paramtype2 = "colorfacedir",
    drawtype = "mesh",
    mesh = "streets_roadwork_cone.obj",
    tiles = {
        { name = "streets_base.png", color = "white" },
        "streets_roadwork_cone.png",
        "streets_blank.png"
    },
    overlay_tiles = {
        "",
        { name = "streets_roadwork_cone_stripes.png", color = "white" },
        ""
    },
    sunlight_propagates = true,
    use_texture_alpha = "clip",
    groups = { snappy = 3, level = 1 },
    selection_box = {
        type = "fixed",
        fixed = { -0.1875, -0.5, -0.1875, 0.1875, 0.375, 0.1875 },
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.1875, -0.5, -0.1875, 0.1875, 0.375, 0.1875 },
    },
    palette = "streets_roadwork_palette.png",
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        for _,drop in ipairs(drops) do
            local meta = drop:get_meta()
            if meta:get_int("palette_index") == 0 then
                meta:set_string("palette_index", "")
            end
        end
    end,
    color = "#f47a00",
    light_source = 2,
})

minetest.register_node("streets:roadwork_traffic_cone_with_light", {
    description = "Traffic Cone with Light",
    paramtype = "light",
    paramtype2 = "colorfacedir",
    drawtype = "mesh",
    mesh = "streets_roadwork_cone.obj",
    tiles = {
        { name = "streets_base.png", color = "white" },
        "streets_roadwork_cone.png",
        {
            name = "streets_roadwork_cone_light.png",
            color = "white",
            animation = {
                type = "vertical_frames",
                aspect_w = 12,
                aspect_h = 12,
                length = 1.5,
            }
        }
    },
    overlay_tiles = {
        "",
        { name = "streets_roadwork_cone_stripes.png", color = "white" },
        ""
    },
    sunlight_propagates = true,
    use_texture_alpha = "clip",
    groups = { snappy = 3, level = 1 },
    selection_box = {
        type = "fixed",
        fixed = { -0.1875, -0.5, -0.1875, 0.1875, 0.375, 0.1875 },
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.1875, -0.5, -0.1875, 0.1875, 0.375, 0.1875 },
    },
    palette = "streets_roadwork_palette.png",
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        for _,drop in ipairs(drops) do
            local meta = drop:get_meta()
            if meta:get_int("palette_index") == 0 then
                meta:set_string("palette_index", "")
            end
        end
    end,
    color = "#f47a00",
    light_source = 2,
})

for idx, color in ipairs({ "orange", "red", "yellow", "pink", "green", "blue", "white", "black" }) do
    minetest.register_craft({
        output = idx == 1 and "streets:roadwork_traffic_cone" or minetest.itemstring_with_palette("streets:roadwork_traffic_cone", (idx-1)*32),
        type = "shapeless",
        recipe = {
            "streets:roadwork_traffic_cone", "dye:"..color
        }
    })

    minetest.register_craft({
        output = idx == 1 and "streets:roadwork_traffic_cone_with_light" or minetest.itemstring_with_palette("streets:roadwork_traffic_cone_with_light", (idx-1)*32),
        type = "shapeless",
        recipe = {
            "streets:roadwork_traffic_cone_with_light", "dye:"..color
        }
    })
end

minetest.register_craft({
    output = "streets:roadwork_traffic_cone 2",
    recipe = {
        {"dye:orange", "basic_materials:plastic_sheet", "dye:white"},
        {"basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet"},
        {"basic_materials:plastic_sheet", "dye:black", "basic_materials:plastic_sheet"},
    },
})

minetest.register_craft({
    output = "streets:roadwork_traffic_cone_with_light",
    type = "shapeless",
    recipe = {"streets:roadwork_traffic_cone", "default:meselamp"}
})

local craft_function = function(itemstack, player, old_craft_grid, craft_inv)
    for _,stack in ipairs(old_craft_grid) do
        if stack:get_name() == "streets:roadwork_traffic_cone" and itemstack:get_name() == "streets:roadwork_traffic_cone_with_light" then
            itemstack:get_meta():set_string("palette_index", stack:get_meta():get_string("palette_index"))
        end
    end
    return itemstack
end

minetest.register_on_craft(craft_function)
minetest.register_craft_predict(craft_function)

minetest.register_node("streets:roadwork_traffic_fence", {
    description = "Traffic Fence",
    paramtype = "light",
    paramtype2 = "facedir",
    drawtype = "mesh",
    mesh = "streets_roadwork_fence.obj",
    tiles = {
        "streets_base.png",
        "streets_roadwork_fence.png",
    },
    sunlight_propagates = true,
    use_texture_alpha = "clip",
    groups = { snappy = 3, level = 1 },
    selection_box = {
        type = "fixed",
        fixed = { -1, -0.5, -1/32, 1, 0.75, 1/32 },
    },
    collision_box = {
        type = "fixed",
        fixed = { -1, -0.5, -1/32, 1, 0.75, 1/32 },
    },
})

minetest.register_craft({
    output = "streets:roadwork_traffic_fence",
    recipe = {
        {"dye:red", "dye:white", "dye:red"},
        {"basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet"},
        {"basic_materials:plastic_sheet", "dye:black", "basic_materials:plastic_sheet"},
    },
})

for name, desc in pairs({
    lights_amber = "Traffic Fence Amber Lights",
    lights_red = "Traffic Fence Red Lights"
}) do
    minetest.register_node("streets:roadwork_traffic_fence_" .. name, {
        description = desc,
        paramtype = "light",
        paramtype2 = "facedir",
        drawtype = "mesh",
        mesh = "streets_roadwork_fence_lights.obj",
        tiles = {
            "streets_roadwork_fence_" .. name .. ".png"
        },
        sunlight_propagates = true,
        use_texture_alpha = "clip",
        groups = { snappy = 3, level = 1 },
        selection_box = {
            type = "fixed",
            fixed = { -1, -0.25, -1/32, 1, 0.25, 1/32 },
        },
        collision_box = {
            type = "fixed",
            fixed = { -1, -0.5, -1/32, 1, 0.75, 1/32 },
        },
        light_source = 3,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if pointed_thing and pointed_thing.type == "node" and minetest.get_node(pointed_thing.under).name == "streets:roadwork_traffic_fence" then
                local above_pos = vector.new(pointed_thing.under.x, pointed_thing.under.y + 1, pointed_thing.under.z)
                if not minetest.is_protected(above_pos, placer:get_player_name()) and minetest.get_node(above_pos).name == "air" then
                    minetest.set_node(above_pos, minetest.get_node(pos))
                    minetest.set_node(pos, { name = "air" })
                end
            end
        end
    })
end

minetest.register_craft({
    output = "streets:roadwork_traffic_fence_lights_amber",
    recipe = {
        {"dye:yellow", "", "dye:yellow"},
        {"default:glass", "default:glass", "default:glass"},
        {"", "default:meselamp", ""},
    },
})

minetest.register_craft({
    output = "streets:roadwork_traffic_fence_lights_red",
    recipe = {
        {"dye:red", "dye:red", "dye:red"},
        {"default:glass", "default:glass", "default:glass"},
        {"default:glass", "default:meselamp", "default:glass"},
    },
})
