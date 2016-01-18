defmodule Hangman.Pattern do 

	def update( pattern, secret, letter ) do
		do_update( String.codepoints(pattern), String.codepoints(secret), letter, [])
	end

	#Base case, first is when secret codepoints list is finished
	defp do_update( _, [], _, value ), do: List.to_string(value)

	#Base case, second is error condition, pattern can't be longer than secret
	defp do_update( [], _,  _, _ ), do: raise "pattern can't be longer than secret"

	#Match only if head of secret is the desired letter
	defp do_update( [ _ | p_tail ], [ letter | s_tail ], letter, value ) do 
		do_update( p_tail, s_tail, letter, [value | letter] )
	end

	#Clause indicating letter not in the secret head, so concat existing pattern character
	defp do_update( [ p_head | p_tail ], [ _ | s_tail ], letter, value ) do 
		do_update( p_tail, s_tail, letter, [value | p_head] )
	end

end

#Hangman.Pattern.update "-------", "beloved",  "e"
