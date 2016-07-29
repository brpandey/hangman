defmodule Hangman.Game.Test do
  use ExUnit.Case, async: true

  alias Hangman.{Game}

  test "fred - game w/o server" do

      game = Game.new("fred", "exotic", 5)

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

      assert %{id: "fred", result: :incorrect_word, code: :game_keep_guessing, 
               pattern: "EXOT--", text: "EXOT--; score=7; status=KEEP_GUESSING",
               summary: []} = result
                                                                    
      {game, result} = Game.guess(game, {:guess_word, "exotic"})
      
      assert %{id: "fred", result: :correct_word, code: :game_won, 
               pattern: "EXOTIC", text: "EXOTIC; score=7; status=GAME_WON"} == result
      
      assert %{id: nil, code: :game_reset, text: 'GAME_RESET'} == Game.status(game)                                
  end

end
