-- VS Code-like CMake workflow for projects that already have CMakeLists.txt.
return {
	{
		"Civitasv/cmake-tools.nvim",
		cmd = {
			"CMakeGenerate",
			"CMakeBuild",
			"CMakeRun",
			"CMakeSelectLaunchTarget",
			"CMakeSelectBuildTarget",
		},
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("cmake-tools").setup({
				cmake_use_preset = true,
				cmake_regenerate_on_save = true,
				cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
				cmake_executor = {
					name = "terminal",
					 opts = {},
					default_opts = {
						terminal = { split_direction = "horizontal", split_size = 15, focus = false },
					},
				},
				cmake_runner = {
					name = "terminal",
					default_opts = {
						terminal = { split_direction = "horizontal", split_size = 15, focus = false },
					},
				},
			})
		end,
	},
}
