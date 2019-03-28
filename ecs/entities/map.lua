local name = "map"

return {
    name = name,
    components = {
        map = {
            width  = 40,
            height = 20,
            setup_params = {
                forest_amount = 4,
                forest_size   = 40,
                forest_spread = 0.9,
                hill_amount   = 4,
                hill_size     = 40,
                hill_smooth   = 2,
                lake_amount   = 2,
                lake_size     = 5,
                river_amount  = 2,
                river_bends   = 1,
            }
        },
        generatable = {},
    }
}