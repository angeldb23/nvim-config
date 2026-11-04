-- CMake helper for simple C++ graphics projects. Known libraries are detected
-- from includes and configured automatically on the first <leader>r.
local M = {}

local GENERATED_MARKER = "# Generated automatically by Angel Neovim"

local function project_name(root)
	local name = vim.fn.fnamemodify(root, ":t")
	name = name:gsub("[^%w_%-]", "_")
	if name == "" or name:match("^%d") then name = "game_" .. name end
	return name
end

local function detect_dependencies(root)
	local found = {}
	local sources = vim.fn.globpath(root, "**/*.{cpp,cc,cxx,h,hpp,hxx}", false, true)
	for _, path in ipairs(sources) do
		if not path:match("/build/") and not path:match("/%.git/")
			and not path:match("/vendor/") and not path:match("/referencias/")
			and not path:match("/third_party/")
		then
			local ok, lines = pcall(vim.fn.readfile, path)
			if ok then
				for _, line in ipairs(lines) do
					if line:match("#%s*include%s*[<\"]raylib%.h[>\"]") then found.raylib = true end
					if line:match("#%s*include%s*[<\"]SDL3/SDL%.h[>\"]") then found.sdl3 = true end
					if line:match("#%s*include%s*[<\"]SDL%.h[>\"]") then found.sdl2 = true end
					if line:match("#%s*include%s*[<\"]GLFW/glfw3%.h[>\"]") then found.glfw = true end
					if line:match("#%s*include%s*[<\"]vulkan/vulkan%.h[>\"]")
						or line:match("#%s*include%s*[<\"]vulkan/vulkan%.hpp[>\"]")
					then found.vulkan = true end
					if line:match("#%s*include%s*[<\"]GL/gl%.h[>\"]")
						or line:match("#%s*include%s*[<\"]OpenGL/gl%.h[>\"]")
						or line:match("#%s*include%s*[<\"]glad/gl%.h[>\"]")
						or line:match("#%s*include%s*[<\"]SDL[23]?/SDL_opengl%.h[>\"]")
					then found.opengl = true end
					if line:match("#%s*include%s*[<\"]GL/glew%.h[>\"]") then found.glew = true end
				end
			end
		end
	end
	if found.glew then found.opengl = true end
	return found
end

local function generated_cmake(name, deps)
	local lines = {
		GENERATED_MARKER,
		"cmake_minimum_required(VERSION 3.20)",
		"project(" .. name .. " LANGUAGES C CXX)",
		"set(CMAKE_CXX_STANDARD 23)",
		"set(CMAKE_CXX_STANDARD_REQUIRED ON)",
		"set(CMAKE_EXPORT_COMPILE_COMMANDS ON)",
	}
	local pkg = {}
	if deps.raylib then pkg[#pkg + 1] = { "RAYLIB", "raylib" } end
	if deps.sdl3 then pkg[#pkg + 1] = { "SDL3", "sdl3" } end
	if deps.sdl2 then pkg[#pkg + 1] = { "SDL2", "sdl2" } end
	if deps.glfw then pkg[#pkg + 1] = { "GLFW3", "glfw3" } end
	if deps.glew then pkg[#pkg + 1] = { "GLEW", "glew" } end
	if #pkg > 0 then
		lines[#lines + 1] = "find_package(PkgConfig REQUIRED)"
		for _, package in ipairs(pkg) do
			lines[#lines + 1] = ("pkg_check_modules(%s REQUIRED IMPORTED_TARGET %s)"):format(package[1], package[2])
		end
	end
	if deps.vulkan then lines[#lines + 1] = "find_package(Vulkan REQUIRED)" end
	if deps.opengl then lines[#lines + 1] = "find_package(OpenGL REQUIRED)" end
	vim.list_extend(lines, {
		"file(GLOB_RECURSE APP_SOURCES CONFIGURE_DEPENDS \"${CMAKE_CURRENT_SOURCE_DIR}/*.cpp\" \"${CMAKE_CURRENT_SOURCE_DIR}/*.cc\" \"${CMAKE_CURRENT_SOURCE_DIR}/*.cxx\")",
		"list(FILTER APP_SOURCES EXCLUDE REGEX \"/(build|\\.git|vendor|referencias)/\")",
		"if(NOT APP_SOURCES)",
		"  message(FATAL_ERROR \"No se encontraron archivos .cpp para compilar\")",
		"endif()",
		"add_executable(" .. name .. " ${APP_SOURCES})",
		"target_compile_options(" .. name .. " PRIVATE -Wall -Wextra)",
	})
	local targets = {
		{ deps.raylib, "PkgConfig::RAYLIB" },
		{ deps.sdl3, "PkgConfig::SDL3" },
		{ deps.sdl2, "PkgConfig::SDL2" },
		{ deps.glfw, "PkgConfig::GLFW3" },
		{ deps.glew, "PkgConfig::GLEW" },
		{ deps.vulkan, "Vulkan::Vulkan" },
		{ deps.opengl, "OpenGL::GL" },
	}
	local links = {}
	for _, target in ipairs(targets) do
		if target[1] then links[#links + 1] = target[2] end
	end
	lines[#lines + 1] = "target_link_libraries(" .. name .. " PRIVATE " .. table.concat(links, " ") .. ")"
	lines[#lines + 1] = ""
	return table.concat(lines, "\n")
end

local function generated_project(root)
	local path = root .. "/CMakeLists.txt"
	local lines = vim.fn.readfile(path)
	return table.concat(lines, "\n"):find(GENERATED_MARKER, 1, true) ~= nil
end

local function run_generated(root)
	local name = project_name(root)
	local build_dir = root .. "/build"
	local exe = build_dir .. "/" .. name
	local command = table.concat({
		"cd " .. vim.fn.shellescape(root),
		"cmake -S " .. vim.fn.shellescape(root) .. " -B " .. vim.fn.shellescape(build_dir),
		"cmake --build " .. vim.fn.shellescape(build_dir) .. " -j",
		vim.fn.shellescape(exe),
	}, " && ")
	vim.cmd("silent! write")
	vim.notify("Building and launching...", vim.log.levels.INFO)
	require("angel.terminal").run_task(command, "Build/run")
end

function M.try_run(file)
	file = vim.fn.fnamemodify(file, ":p")
	local root = vim.fs.root(file, { "CMakeLists.txt" }) or vim.fs.dirname(file)
	local cmake_path = root .. "/CMakeLists.txt"
	local stat = vim.uv.fs_stat(cmake_path)

	if stat and generated_project(root) then
		run_generated(root)
		return true
	end
	if stat then
		vim.cmd("CMakeRun")
		return true
	end

	local deps = detect_dependencies(root)
	local recognized = next(deps) ~= nil
	if vim.bo.filetype == "cpp" and recognized and (not stat or generated_project(root)) then
		local ok, err = pcall(vim.fn.writefile, vim.split(generated_cmake(project_name(root), deps), "\n"), cmake_path)
		if not ok then
			vim.notify("Could not generate build config: " .. tostring(err), vim.log.levels.ERROR)
			return true
		end
		vim.notify("Libraries found. Project setup created.", vim.log.levels.INFO)
		run_generated(root)
		return true
	end

	return false
end

function M.build_existing(file)
	local root = vim.fs.root(vim.fn.fnamemodify(file, ":p"), { "CMakeLists.txt" })
	if not root then return false end
	vim.cmd("CMakeBuild")
	return true
end

return M
