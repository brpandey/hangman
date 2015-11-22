defmodule Hangman.Server.Test do
	use ExUnit.Case, async: true

	test "guessing letters and checking letter positions" do

		{:ok, _pid} = Hangman.Server.start_link("avocado", 5)

		assert {:correct_letter, "--O---O", Nil} = Hangman.Server.guess_letter("o")

		assert {:correct_letter, "--OC--O", Nil} = Hangman.Server.guess_letter("c")

		assert {:incorrect_letter, Nil, Nil} = Hangman.Server.guess_letter("x")

		assert {:correct_letter, "--OC-DO", Nil} = Hangman.Server.guess_letter("d")

		assert  {:correct_letter, "--OC-DO", Nil} = Hangman.Server.guess_letter("d")

		assert {:incorrect_letter, Nil, Nil} = Hangman.Server.guess_letter("f")

		assert {:correct_letter, "-VOC-DO", Nil} = Hangman.Server.guess_letter("v")

		assert {:correct_letter, "AVOCADO", _text} = Hangman.Server.guess_letter("a")

		Hangman.Server.stop

	end

	test "returns correct game status" do

		{:ok, _pid} = Hangman.Server.start_link("avocado", 5)

		assert {:game_keep_guessing, 0, _text} = Hangman.Server.game_status()

		Hangman.Server.guess_letter("c") 

		assert {:game_keep_guessing, 1, _text} = Hangman.Server.game_status() 

		Hangman.Server.guess_letter("a") 

		assert {:game_keep_guessing, 2, "A--CA--; score=2; status=KEEP_GUESSING"} 
			= Hangman.Server.game_status() 

		Hangman.Server.guess_word "ashcans"

		assert {:game_keep_guessing, 3, "A--CA--; score=3; status=KEEP_GUESSING"} 
			= Hangman.Server.game_status() 

		Hangman.Server.guess_letter("x") 

		assert {:game_keep_guessing, 4, _text} = Hangman.Server.game_status() 

		Hangman.Server.guess_letter("o") 

		assert {:game_keep_guessing, 5, "A-OCA-O; score=5; status=KEEP_GUESSING"} 
			= Hangman.Server.game_status() 

		assert {:correct_word, {:game_won, 'GAME_WON', 5}} = Hangman.Server.guess_word("avocado")

		assert {:game_won, 5, "AVOCADO; score=5; status=GAME_WON"} = Hangman.Server.game_status 

		Hangman.Server.stop

	end

end
