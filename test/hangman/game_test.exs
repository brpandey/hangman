defmodule Hangman.Game.Test do
  use ExUnit.Case, async: true
  alias Hangman.Game

  test "fred - game w/o server" do
    game = Game.new("fred", "exotic", 5)

    # correct letter x 1
    {game, _result} = Game.guess(game, {:guess_letter, "x"})

    # correct letter o 2
    {game, result} = Game.guess(game, {:guess_letter, "o"})

    assert %{
             id: "fred",
             code: :guessing,
             pattern: "-XO---",
             result: :correct_letter,
             text: "-XO---; score=2; status=KEEP_GUESSING"
           } = result

    # correct letter t 3
    {game, _result} = Game.guess(game, {:guess_letter, "t"})

    # incorrect letter u 4
    {game, _result} = Game.guess(game, {:guess_letter, "u"})

    {game, status} = Game.status(game)

    assert %{id: "fred", code: :guessing, text: "-XOT--; score=4; status=KEEP_GUESSING"} = status

    # incorrect letter s 5
    {game, _result} = Game.guess(game, {:guess_letter, "s"})

    # correct letter e 6
    {game, _result} = Game.guess(game, {:guess_letter, "e"})

    # incorrect word exotly 7
    {game, result} = Game.guess(game, {:guess_word, "exotly"})

    game_text =
      "#Game<[id: \"fred\", state: :guessing, current_game_index: 0, secret: \"EXOTIC\", pattern: \"EXOT--\", score: 0, secrets: [\"EXOTIC\"], patterns: [], scores: [], max_wrong_guesses: 5, guessed_letters: [correct: [\"E\", \"O\", \"T\", \"X\"], incorrect: [\"S\", \"U\"]], guessed_words: [incorrect: [\"EXOTLY\"]]]>"

    assert game_text == "#{inspect(game)}"

    assert %{
             id: "fred",
             result: :incorrect_word,
             code: :guessing,
             pattern: "EXOT--",
             text: "EXOT--; score=7; status=KEEP_GUESSING"
           } = result

    {game, result} = Game.guess(game, {:guess_word, "exotic"})

    assert %{
             id: "fred",
             result: :correct_word,
             code: :won,
             pattern: "EXOTIC",
             text: "EXOTIC; score=7; status=GAME_WON"
           } == result

    {game, feedback} = Game.status(game)

    assert %{
             code: :finished,
             id: "fred",
             text: "Game Over! Average Score: 7.0, Games: 1, Scores:  (EXOTIC: 7)"
           } == feedback

    {_game, feedback} = Game.status(game)

    assert %{code: :reset, id: "fred", text: "GAMES_RESET"} == feedback
  end
end
