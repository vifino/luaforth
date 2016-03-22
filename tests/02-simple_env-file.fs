\ 02-simple_env-file.fs
\ Comments, yay.

\ Small "emit" thing.
: emit [L local args = {...} local stack, env = unpack(args) print(stack[#stack]) L] ; \ this is ugly, but oh well.

\ 123 emit \ Should write "123\n". Commented out because ugly output in busted.
