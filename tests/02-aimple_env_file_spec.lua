describe("LuaForth", function()
	local luaforth = require("luaforth")
	it("should run 02-simple_env-file.fs", function()
		local f = assert(io.open("tests/02-simple_env-file.fs"))
		local src = f:read"*all"
		f:close()
		luaforth.eval(src, luaforth.simple_env)
	end)
end)
