defmodule Game.Test do
  use ExUnit.Case, async: true

# alias Hangman.{Game}

  test "fred - game w/o server" do

      game = Game.load("fred", "exotic", 5)

      # correct letter x 1
      {game, _result} = Game.guess(game, {:guess_letter, "x"})

      # correct letter o 2
      {game, _result} = Game.guess(game, {:guess_letter, "o"})

      # correct letter t 3
      {game, _result} = Game.guess(game, {:guess_letter, "t"})

      # incorrect letter u 4
      {game, _result} = Game.guess(game, {:guess_letter, "u"})

      # incorrect letter s 5
      {game, _result} = Game.guess(game, {:guess_letter, "s"})

      # correct letter e 6
      {game, _result} = Game.guess(game, {:guess_letter, "e"})

      # incorrect word exotly 7
      {game, result} = Game.guess(game, {:guess_word, "exotly"})

      game_text = "#Game<[id: \"fred\", client_pid: nil, finished: false, current_game_index: 0, secret: \"EXOTIC\", pattern: \"EXOT--\", score: 0, secrets: [], patterns: [], scores: [], max_wrong_guesses: 5, guessed_letters: [correct: [\"E\", \"O\", \"T\", \"X\"], incorrect: [\"S\", \"U\"]], guessed_words: [incorrect: [\"EXOTLY\"]]]>"


      assert game_text == "#{inspect game}"

      assert {{"fred", :incorrect_word, :game_keep_guessing, "EXOT--",
               "EXOT--; score=7; status=KEEP_GUESSING"}, []} = result
                                                                    
      {game, result} = Game.guess(game, {:guess_word, "exotic"})

      assert {"fred", :correct_word, :game_won, "EXOTIC",
              "EXOTIC; score=7; status=GAME_WON"} == result
      
      assert {nil, :game_reset, 'GAME_RESET'} == Game.status(game)                                
  end

end
