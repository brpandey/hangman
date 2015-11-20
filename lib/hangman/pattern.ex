defmodule Hangman.Pattern do 

	def update( pattern, secret, letter ) do
		_update( String.codepoints(pattern), String.codepoints(secret), letter, [])
	end

	#Base case, first is when secret codepoints list is finished
	defp _update( _, [], _, value ), do: List.to_string(value)

	#Base case, second is error condition, pattern can't be longer than secret
	defp _update( [], _,  _, _ ), do: raise "pattern can't be longer than secret"

	#Match only if head of secret is the desired letter
	defp _update( [ _ | p_tail ], [ letter | s_tail ], letter, value ) do 
		_update( p_tail, s_tail, letter, [value | letter] )
	end

	#Clause indicating letter not in the secret head, so concat existing pattern character
	defp _update( [ p_head | p_tail ], [ _ | s_tail ], letter, value ) do 
		_update( p_tail, s_tail, letter, [value | p_head] )
	end

end

#Hangman.Pattern.update "-------", "beloved",  "e"
