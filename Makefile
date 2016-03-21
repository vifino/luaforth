# LuaForth Makefile

test: tests
	busted $<

lint: luaforth.lua
	luacheck $<

all: test
