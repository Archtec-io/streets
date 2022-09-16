minetest.register_node("streets:guardrail", {
    description = "Guardrail",
    paramtype = "light",
    drawtype = "nodebox",
    tiles = { "streets_guardrail.png" },
    sunlight_propagates = true,
    groups = { cracky = 1, wall = 1 },
    node_box = {
        type = "connected",
        fixed = {
            { -0.1, -0.5, -0.1, 0.1, 0.5, 0.1 },
        },
        connect_front = {
            { 0, -0.1875, -0.5, 0, 0.4375, 0 },
            { -0.0625, 0.1875, -0.5, 0.0625, 0.3125, 0 },
            { -0.0625, -0.0625, -0.5, 0.0625, 0.0625, 0 },
        }, -- z-
        connect_back = {
            { 0, -0.1875, 0, 0, 0.4375, 0.5 },
            { -0.0625, 0.1875, 0, 0.0625, 0.3125, 0.5 },
            { -0.0625, -0.0625, 0, 0.0625, 0.0625, 0.5 },
        }, -- z+
        connect_left = {
            { -0.5, -0.1875, 0, 0, 0.4375, 0 },
            { -0.5, 0.1875, -0.0625, 0, 0.3125, 0.0625 },
            { -0.5, -0.0625, -0.0625, 0, 0.0625, 0.0625 },
        }, -- x-
        connect_right = {
            { 0, -0.1875, 0, 0.5, 0.4375, 0 },
            { 0, 0.1875, -0.0625, 0.5, 0.3125, 0.0625 },
            { 0, -0.0625, -0.0625, 0.5, 0.0625, 0.0625 },
        }, -- x+
    },
    collision_box = {
        type = "connected",
        fixed = {
            { -0.1, -0.5, -0.1, 0.1, 0.5, 0.1 },
        },
        connect_front = {
            { -0.1, -0.1875, -0.5, 0.1, 0.4375, 0 },
        }, -- z-
        connect_back = {
            { -0.1, -0.1875, 0, 0.1, 0.4375, 0.5 },
        }, -- z+
        connect_left = {
            { -0.5, -0.1875, -0.1, 0, 0.4375, 0.1 },
        }, -- x-
        connect_right = {
            { 0, -0.1875, -0.1, 0.5, 0.4375, 0.1 },
        }, -- x+
    },
    connects_to = { "group:wall", "group:stone", "group:wood", "group:tree", "group:concrete" },
    sound = default.node_sound_metal_defaults()
})

minetest.register_craft({
    output = "streets:guardrail 12",
    recipe = {
        { "basic_materials:steel_bar", "default:steel_ingot", "basic_materials:steel_bar" },
        { "basic_materials:steel_bar", "default:steel_ingot", "basic_materials:steel_bar" },
        { "", "default:steel_ingot", "" },
    }
})

minetest.register_node("streets:concrete_wall", {
    description = "Concrete Wall",
    paramtype = "light",
    drawtype = "nodebox",
    tiles = { "basic_materials_concrete_block.png" },
    sunlight_propagates = true,
    groups = { cracky = 1, level = 2, wall = 1 },
    node_box = {
        type = "connected",
        fixed = { { -0.35, -0.5, -0.35, 0.35, -0.4, 0.35 }, { -0.15, -0.5, -0.15, 0.15, 0.5, 0.15 } },
        connect_front = { { -0.35, -0.5, -0.5, 0.35, -0.4, 0.35 }, { -0.15, -0.5, -0.5, 0.15, 0.5, 0.15 } }, -- z-
        connect_back = { { -0.35, -0.5, -0.35, 0.35, -0.4, 0.5 }, { -0.15, -0.5, -0.15, 0.15, 0.5, 0.5 } }, -- z+
        connect_left = { { -0.5, -0.5, -0.35, 0.35, -0.4, 0.35 }, { -0.5, -0.5, -0.15, 0.15, 0.5, 0.15 } }, -- x-
        connect_right = { { -0.35, -0.5, -0.35, 0.5, -0.4, 0.35 }, { -0.15, -0.5, -0.15, 0.5, 0.5, 0.15 } }, -- x+
    },
    connects_to = { "group:wall", "group:stone", "group:wood", "group:tree", "group:concrete" },
    sound = default.node_sound_stone_defaults()
})


minetest.register_craft({
    output = "streets:concrete_wall 5",
    recipe = {
        { "", "basic_materials:concrete_block", "" },
        { "", "basic_materials:concrete_block", "" },
        { "basic_materials:concrete_block", "basic_materials:concrete_block", "basic_materials:concrete_block" },
    }
})

minetest.register_node("streets:concrete_wall_top", {
    description = "Concrete Wall (Top)",
    paramtype = "light",
    drawtype = "nodebox",
    tiles = { "basic_materials_concrete_block.png" },
    sunlight_propagates = true,
    groups = { cracky = 1, level = 2, wall = 1 },
    node_box = {
        type = "connected",
        fixed = { -0.15, -0.5, -0.15, 0.15, 0.5, 0.15 },
        connect_front = { -0.15, -0.5, -0.5, 0.15, 0.5, 0.15 }, -- z-
        connect_back = { -0.15, -0.5, -0.15, 0.15, 0.5, 0.5 }, -- z+
        connect_left = { -0.5, -0.5, -0.15, 0.15, 0.5, 0.15 }, -- x-
        connect_right = { -0.15, -0.5, -0.15, 0.5, 0.5, 0.15 }, -- x+
    },
    connects_to = { "group:wall", "group:stone", "group:wood", "group:tree", "group:concrete" },
    sound = default.node_sound_stone_defaults()
})

minetest.register_craft({
    output = "streets:concrete_wall_top",
    recipe = {
        { "streets:concrete_wall" },
    }
})

minetest.register_craft({
    output = "streets:concrete_wall",
    recipe = {
        { "streets:concrete_wall_top" },
    }
})