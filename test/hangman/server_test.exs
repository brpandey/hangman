defmodule Hangman.Server.Test do
	use ExUnit.Case, async: true

	test "guessing letters, checking letter positions and winning game" do

		assert {:ok, _pid} = Hangman.Server.start_link("avocado", 5)

		assert {{:correct_letter, :game_keep_guessing, "--O---O", _text}, []} = 
			Hangman.Server.guess_letter("o")

		assert {{:correct_letter, :game_keep_guessing, "--OC--O", _text}, []} =
			Hangman.Server.guess_letter("c")

		assert {{:incorrect_letter, :game_keep_guessing, _pattern, _text}, []} = 
			Hangman.Server.guess_letter("x")

		assert {{:correct_letter, :game_keep_guessing, "--OC-DO", _text}, []} = 
			Hangman.Server.guess_letter("d")

		assert {{:correct_letter, :game_keep_guessing, "--OC-DO", _text}, []} = 
			Hangman.Server.guess_letter("d")

		assert {{:incorrect_letter, :game_keep_guessing, _pattern, _text}, []} = 
			Hangman.Server.guess_letter("f")

		assert {{:correct_letter, :game_keep_guessing, "-VOC-DO", _text}, []} = 
			Hangman.Server.guess_letter("v")

		assert {{:correct_letter, :game_won, "AVOCADO", _text}, []} = 
			Hangman.Server.guess_letter("a")

		assert :ok = Hangman.Server.stop

	end

	test "guessing letters, checking letter positions and losing game" do

		assert {:ok, _pid} = Hangman.Server.start_link("fantastic", 5)

		assert {{:correct_letter, :game_keep_guessing, "-A--A----", _text}, []} = 
			Hangman.Server.guess_letter("a")

		#Test invaid input, see if the game continues on with the same score (check not penalized)
		#Hangman.Server.guess_letter(123)

		assert {:game_keep_guessing, "-A--A----; score=1; status=KEEP_GUESSING"} =
			Hangman.Server.game_status()

		assert {{:correct_letter, :game_keep_guessing, "-A--A---C", _text}, []} =
			Hangman.Server.guess_letter("c")

		#Hangman.Server.guess_word(456)

		assert {:game_keep_guessing, "-A--A---C; score=2; status=KEEP_GUESSING"} =
			Hangman.Server.game_status()

		assert {{:correct_letter, :game_keep_guessing, "-AN-A---C", _text}, []} =
			Hangman.Server.guess_letter("n") 

		assert {{:correct_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} = 
			Hangman.Server.guess_letter("t")	

		#Now a string of 6 incorrect guesses (the max wrong guesses is 5)
		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Hangman.Server.guess_letter("m")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Hangman.Server.guess_letter("l")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Hangman.Server.guess_letter("r")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} = 
			Hangman.Server.guess_letter("b")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Hangman.Server.guess_letter("h")

		#At this point we have reached our 5 incorrect guesses, this next guess better be right!
		assert {{:incorrect_letter, :game_lost, "-ANTA-T-C", 
			"-ANTA-T-C; score=25; status=GAME_LOST"}, []} =
			 Hangman.Server.guess_letter("k")
	
		assert Hangman.Server.stop() == :ok

	end

	test "returns correct game status" do

		{:ok, _pid} = Hangman.Server.start_link("avocado", 5)

		assert {:game_keep_guessing, _text} = Hangman.Server.game_status()

		Hangman.Server.guess_letter("c") 

		assert {:game_keep_guessing, _text} = Hangman.Server.game_status() 

		Hangman.Server.guess_letter("a") 

		assert {:game_keep_guessing, "A--CA--; score=2; status=KEEP_GUESSING"} =
			Hangman.Server.game_status()

		Hangman.Server.guess_word "ashcans"

		assert {:game_keep_guessing, "A--CA--; score=3; status=KEEP_GUESSING"} =
			Hangman.Server.game_status() 

		Hangman.Server.guess_letter("x") 

		assert {:game_keep_guessing, _text} = Hangman.Server.game_status() 

		Hangman.Server.guess_letter("o") 

		assert {:game_keep_guessing, "A-OCA-O; score=5; status=KEEP_GUESSING"} =
			Hangman.Server.game_status() 

		assert {{:correct_word, :game_won, _pattern, _text}, []} = 
			Hangman.Server.guess_word("avocado")

		assert {:game_reset, 'GAME_RESET'} = Hangman.Server.game_status 

		assert Hangman.Server.stop() == :ok

	end

'''
	test "another game" do

		#Game 1
		#avocado

		{:ok, _pid} = Hangman.Server.start_link_link("avocado", 5)

		assert {:correct_letter, :game_keep_guessing, "A---A--", _text} =
			Hangman.Server.guess_letter("a")

		assert {:correct_letter, :game_keep_guessing, "A-O-A-O", _text} =
			Hangman.Server.guess_letter("o")

		assert {:correct_letter, :game_keep_guessing, "AVO-A-O", _text} =
			Hangman.Server.guess_letter("v")

		assert {:correct_letter, :game_keep_guessing, "AVO-ADO", _text} =
			Hangman.Server.guess_letter("d")

		assert {:correct_word, :game_won, "AVOCADO", _text} =
			Hangman.Server.guess_word("avocado")

		#Game 2
		#mystical
		assert Hangman.Server.another_game("mystical") == :ok     

		assert {:correct_letter, :game_keep_guessing, "--S-----", _text} =
			Hangman.Server.guess_letter("s")

		assert {:correct_letter, :game_keep_guessing, "--S---A-", _text} =
			Hangman.Server.guess_letter("a")

		assert {:correct_letter, :game_keep_guessing, "--ST--A-",_text} =
			Hangman.Server.guess_letter("t")

		assert {:correct_letter, :game_keep_guessing, "M-ST--A-",
 			"M-ST--A-; score=4; status=KEEP_GUESSING"} =
 			Hangman.Server.guess_letter("m")

		assert {:correct_word, :game_won, "MYSTICAL", 
			"MYSTICAL; score=4; status=GAME_WON"} =
			Hangman.Server.guess_word("mystical")

		#Game 3
		#lampoon
		assert Hangman.Server.another_game("lampoon") == :ok     

		assert {:correct_letter, :game_keep_guessing, "--M----", _text} =
			Hangman.Server.guess_letter("m")

		assert {:correct_letter, :game_keep_guessing, "--M-OO-", _text} =
			Hangman.Server.guess_letter("o")

		assert {:correct_letter, :game_keep_guessing, "--MPOO-", _text} =
			Hangman.Server.guess_letter("p")

		assert {:correct_word, :game_won, "LAMPOON", _text} =
			Hangman.Server.guess_word("lampoon")

		assert {:game_won, 3, "LAMPOON; score=3; status=GAME_WON"} =
			Hangman.Server.game_status()

		#Game 4
		#dexterity
		assert Hangman.Server.another_game("dexterity") == :ok     

		assert {:correct_letter, :game_keep_guessing, "-E--E----", _text} =
			Hangman.Server.guess_letter("e")

		assert {:correct_word, :game_won, "DEXTERITY", "DEXTERITY; score=1; status=GAME_WON"} =
			Hangman.Server.guess_word("dexterity")

		assert {:game_won, 1, "DEXTERITY; score=1; status=GAME_WON"} = 
			Hangman.Server.game_status()

		assert Hangman.Server.stop() == :ok

	end
'''

end
