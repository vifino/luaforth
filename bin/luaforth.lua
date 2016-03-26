#!/usr/bin/env lua
-- small repl kinda thing for luaforth
local luaforth = require("luaforth")

print("LuaForth "..luaforth.version)
print("Type 'exit' to exit.\n")

local function readline(prompt)
	if linenoise then -- running in carbon
		local line, err = linenoise.line(prompt)
		if err then return nil end
		linenoise.addHistory(line)
		return line
	else
		io.stdout:write(prompt)
		return io.stdin:read"*line"
	end
end

local stack
local env = luaforth.simple_env
while true do
	local src = readline("=> ")
	if src == "exit" then
		break
	elseif src then
		success, new_stack, new_env = pcall(luaforth.eval, src, env, stack) -- eval, putting the resulting stack and env in a new variable
		if not success then
			print(new_stack) -- actually error on failure
		else
			stack, env = new_stack or stack, new_env or env -- if it succeeded in executing the source, replace
		end
	else
		break
	end
end
