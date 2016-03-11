defmodule Pattern do
  @moduledoc """
  Module handles `Hangman` pattern updates given guessed `letter`.
  """

  @doc """
  Recursive function, returns `pattern` string after update
  """

	@spec update(String.t, String.t, String.t) :: String.t | no_return
	def update( pattern, secret, letter ) do
		do_update(String.codepoints(pattern), String.codepoints(secret), letter, [])
	end


	# Base case, first is when secret codepoints list is finished
	@spec do_update(term, [], term, [...]) :: String.t
	defp do_update( _, [], _, value ), do: List.to_string(value)


	# Base case, second is error condition, pattern can't be longer than secret
	@spec do_update([], term, term, term) :: no_return
	defp do_update( [], _,  _, _ ), do: raise HangmanError, "pattern can't be longer than secret"


	# Match only if head of secret is the desired letter
	@spec do_update([...], [...], String.t, [...]) :: String.t | no_return
	defp do_update( [ _ | p_tail ], [ letter | s_tail ], letter, value ) do 
		do_update( p_tail, s_tail, letter, [value | letter] )
	end


	# Clause indicating letter not in the secret head, so concat existing pattern character
	@spec do_update([...], [...], String.t, [...]) :: String.t | no_return
	defp do_update( [ p_head | p_tail ], [ _ | s_tail ], letter, value ) do 
		do_update( p_tail, s_tail, letter, [value | p_head] )
	end

end

#Pattern.update "-------", "beloved",  "e"
