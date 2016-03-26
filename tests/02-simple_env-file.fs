\ 02-simple_env-file.fs
\ Comments, yay.

\ Small "emit" thing.
\ : emit [L local args = {...} local stack, env = unpack(args) print(stack[#stack]) L] ; \ this is ugly, but...
:[L emit 1 local args = {...} print(args[1]) L]; \ is much better, although it can definitly see some improvement.

\ 123 emit \ Should write "123\n". Commented out because ugly output in busted.
