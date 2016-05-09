describe("LuaForth", function()
	describe("should, when given simple_env, be able to", function()
		local luaforth = require("luaforth")
		describe("use [L and L] to", function()
			describe("push a", function()
				it("number", function()
					local stack = luaforth.eval("[L return 123 L]", luaforth.simple_env)
					assert.are.equals(stack[1], 123)
				end)
				it("string", function()
					local stack = luaforth.eval("[L return 'Hello world!' L]", luaforth.simple_env)
					assert.are.equals(stack[1], "Hello world!")
				end)
				it("boolean", function()
					local stack = luaforth.eval("[L return true L]", luaforth.simple_env)
					assert.is_true(stack[1])
				end)
			end)
		end)
		describe("use %L to", function()
			it("eval a whole line of lua", function()
				local stack = luaforth.eval("%L return 'Tomato!'", luaforth.simple_env)
				assert.are.equals(stack[1], "Tomato!")
			end)
			it("eval and error in a line of lua code", function()
				assert.has_error(function()
					luaforth.eval("%L error('Not enough pizza!')", luaforth.simple_env)
				end)
			end)
			it("eval two lines of lua", function()
				local stack = luaforth.eval("%L return 'Tomato!'\n%L return 'Another tomato!'\n", luaforth.simple_env)
				assert.are.equals(stack[1], "Tomato!")
				assert.are.equals(stack[2], "Another tomato!")
			end)
		end)
		describe("use [L and L] to", function()
			it("eval a snippet of lua", function()
				local stack = luaforth.eval("[L return 'Tomato!' L]", luaforth.simple_env)
				assert.are.equals(stack[1], "Tomato!")
			end)
			it("eval and error in a snippet of lua code", function()
				assert.has_error(function()
					luaforth.eval("[L error('Not enough pizza!') L]", luaforth.simple_env)
				end)
			end)
		end)
		describe("define words", function()
			it("with forth code itself", function()
				local stack = luaforth.eval(": hello [L return 'Hello world!' L] ; hello", luaforth.simple_env)
				assert.are.equals(stack[1], "Hello world!")
			end)
			it("using lua", function()
				local stack = luaforth.eval([[ :[L hello_lua 0 return "Hello from Lua!" L]; hello_lua ]], luaforth.simple_env)
				assert.are.equals(stack[1], "Hello from Lua!")
			end)
		end)
		describe("create", function()
			it("plain numbers", function()
				local stack = luaforth.eval("123", luaforth.simple_env)
				assert.are.equals(stack[1], 123)
			end)
			it("basic strings using s'", function()
				local stack = luaforth.eval("s' Hello World!'", luaforth.simple_env)
				assert.are.equals(stack[1], "Hello World!")
			end)
		end)
	end)
end)
