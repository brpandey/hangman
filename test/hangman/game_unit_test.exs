defmodule Hangman.Game.UnitTest do
  use ExUnit.Case, async: true
  alias Hangman.Game

  describe "game with single secret" do
    setup :setup_single_game

    test "comparison equals operator with equivalent game", %{game: game} do
      compare = Game.new("orange", "GenEalogy", 2)
      assert Game.equal?(game, compare)
    end

    test "comparison equals operator with non-equivalent game", %{game: game} do
      compare = Game.new("orange1", "genealogy", 2)
      assert false == Game.equal?(game, compare)
    end

    test "comparison equals operator with non-equivalent game in further stage", %{game: game} do
      compare = Game.new("orange", "genealogy", 2)
      {game, _result} = Game.guess(game, {:guess_letter, "g"})
      assert false == Game.equal?(game, compare)
    end

    test "should not be empty", %{game: game} do
      assert false == game |> Game.empty?()
    end

    test "secret length should be valid", %{game: game} do
      assert String.length("genealogy") == game |> Game.secret_length()
    end

    test "should error when secret is too short", %{game: _game} do
      assert catch_error(Game.new("orange", "g", 2)) ==
               %HangmanError{message: "Secret submitted is too short"}
    end

    test "guess correct letter", %{game: game} do
      {_game, result} = Game.guess(game, {:guess_letter, "e"})

      assert %{
               code: :guessing,
               id: "orange",
               pattern: "-E-E-----",
               result: :correct_letter,
               text: "-E-E-----; score=1; status=KEEP_GUESSING"
             } = result
    end

    test "guess incorrect letter", %{game: game} do
      {_game, result} = Game.guess(game, {:guess_letter, "s"})

      assert %{
               code: :guessing,
               id: "orange",
               pattern: "---------",
               result: :incorrect_letter,
               text: "---------; score=1; status=KEEP_GUESSING"
             } = result
    end

    test "guess correct word", %{game: game} do
      {_game, result} = Game.guess(game, {:guess_word, "genealogy"})

      assert %{
               id: "orange",
               result: :correct_word,
               code: :won,
               pattern: "GENEALOGY",
               text: "GENEALOGY; score=0; status=GAME_WON"
             } == result
    end

    test "guess incorrect word", %{game: game} do
      {_game, result} = Game.guess(game, {:guess_word, "geriatric"})

      assert %{
               id: "orange",
               code: :guessing,
               pattern: "---------",
               result: :incorrect_word,
               text: "---------; score=1; status=KEEP_GUESSING"
             } == result
    end

    test "game status when start with no guesses", %{game: game} do
      {_game, feedback} = Game.status(game)

      assert %{id: "orange", code: :guessing, text: "---------; score=0; status=KEEP_GUESSING"} ==
               feedback
    end

    test "game status after abort", %{game: game} do
      game = Game.abort(game)
      {_game, feedback} = Game.status(game)

      assert %{
               code: :finished,
               id: "orange",
               text: "Game Over! Average Score: 0, Games: 0, Scores:  (GENEALOGY: 0)"
             } == feedback
    end

    test "game status after 1st incorrect guess", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "t"})
      {_game, feedback} = Game.status(game)

      assert %{id: "orange", code: :guessing, text: "---------; score=1; status=KEEP_GUESSING"} ==
               feedback
    end

    test "game status after 2nd incorrect guess", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "t"})
      {game, _result} = Game.guess(game, {:guess_letter, "r"})

      {_game, feedback} = Game.status(game)

      assert %{id: "orange", code: :guessing, text: "---------; score=2; status=KEEP_GUESSING"} ==
               feedback
    end

    test "game status after 3rd incorrect guess given max 2 wrong guesses", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "t"})
      {game, _result} = Game.guess(game, {:guess_letter, "r"})
      {game, _result} = Game.guess(game, {:guess_letter, "f"})

      {_game, feedback} = Game.status(game)

      assert %{
               id: "orange",
               code: :finished,
               text: "Game Over! Average Score: 25.0, Games: 1, Scores:  (GENEALOGY: 25)"
             } == feedback
    end

    test "game status after 1st correct guess", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "g"})
      {_game, feedback} = Game.status(game)

      assert %{id: "orange", code: :guessing, text: "G------G-; score=1; status=KEEP_GUESSING"} ==
               feedback
    end

    test "game status after 2nd correct guess", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "g"})
      {game, _result} = Game.guess(game, {:guess_letter, "l"})

      {_game, feedback} = Game.status(game)

      assert %{id: "orange", code: :guessing, text: "G----L-G-; score=2; status=KEEP_GUESSING"} ==
               feedback
    end

    test "guess next error if game still being played", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "g"})

      assert catch_error(Game.next(game)) ==
               %HangmanError{
                 message: "not supported - calling of next when single game is not over"
               }
    end

    test "guess next return game over if game over", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "g"})
      {game, _result} = Game.guess(game, {:guess_word, "genealogy"})
      {_game, feedback} = Game.next(game)

      assert %{
               code: :finished,
               id: "orange",
               text: "Game Over! Average Score: 1.0, Games: 1, Scores:  (GENEALOGY: 1)"
             } == feedback
    end
  end

  describe "game with multiple secrets" do
    setup :setup_multiple_games

    test "comparison equals operator with equivalent game", %{game: game} do
      compare = Game.new("orange", ["genealogy", "probiotic"], 2)
      assert Game.equal?(game, compare)
    end

    test "comparison equals operator with non-equivalent game", %{game: game} do
      compare = Game.new("orange", ["genealogy", "probiotics"], 2)
      assert false == Game.equal?(game, compare)
    end

    test "comparison equals operator with non-equivalent game in further stage", %{game: game} do
      compare = Game.new("orange", ["genealogy", "probiotic"], 2)
      {game, _result} = Game.guess(game, {:guess_letter, "g"})
      assert false == Game.equal?(game, compare)
    end

    test "guess next, error if game still being played", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "g"})
      {game, _result} = Game.guess(game, {:guess_word, "genealogy"})

      {game, _feedback} = Game.next(game)

      {game, _result} = Game.guess(game, {:guess_letter, "p"})

      assert catch_error(Game.next(game)) ==
               %HangmanError{
                 message: "not supported - calling of next when single game is not over"
               }
    end

    test "guess next return next game when first game finished", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "g"})
      {game, _result} = Game.guess(game, {:guess_word, "genealogy"})
      {game, feedback} = Game.next(game)

      assert %{
               id: "orange",
               code: :start,
               text: 'GAME_START',
               previous: %{code: :won, id: "orange", text: "GENEALOGY; score=1; status=GAME_WON"}
             } == feedback

      {_game, result} = Game.guess(game, {:guess_letter, "p"})

      assert %{
               code: :guessing,
               id: "orange",
               pattern: "P--------",
               result: :correct_letter,
               text: "P--------; score=1; status=KEEP_GUESSING"
             } == result
    end

    test "guess next return game over when all games finished", %{game: game} do
      {game, _result} = Game.guess(game, {:guess_letter, "g"})
      {game, _result} = Game.guess(game, {:guess_word, "genealogy"})
      {game, _feedback} = Game.next(game)

      {game, _result} = Game.guess(game, {:guess_letter, "p"})
      {game, result} = Game.guess(game, {:guess_letter, "o"})

      assert %{
               code: :guessing,
               id: "orange",
               pattern: "P-O--O---",
               result: :correct_letter,
               text: "P-O--O---; score=2; status=KEEP_GUESSING"
             } == result

      {game, result} = Game.guess(game, {:guess_letter, "i"})

      assert %{
               code: :guessing,
               id: "orange",
               result: :correct_letter,
               pattern: "P-O-IO-I-",
               text: "P-O-IO-I-; score=3; status=KEEP_GUESSING"
             } == result

      {game, result} = Game.guess(game, {:guess_word, "probiotic"})

      assert %{
               id: "orange",
               code: :won,
               text: "PROBIOTIC; score=3; status=GAME_WON",
               pattern: "PROBIOTIC",
               result: :correct_word
             } == result

      {_game, feedback} = Game.next(game)

      assert %{
               code: :finished,
               id: "orange",
               text:
                 "Game Over! Average Score: 2.0, Games: 2, Scores:  (GENEALOGY: 1) (PROBIOTIC: 3)"
             } == feedback
    end
  end

  defp setup_single_game(_context) do
    game = Game.new("orange", "genealogy", 2)
    [game: game]
  end

  defp setup_multiple_games(_context) do
    game = Game.new("orange", ["genealogy", "probiotic"], 2)
    [game: game]
  end
end
