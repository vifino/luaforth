describe("LuaForth", function()
	local luaforth = require("luaforth")
	it("should be able to source 03-simple_env-sourcing.fs", function()
		local stack = luaforth.eval("%source tests/03-simple_env-sourcing.fs", luaforth.simple_env)
		assert.are.same(stack[1], "Works!")
	end)
end)