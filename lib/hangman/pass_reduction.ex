defmodule Hangman.Pass.Reduction do
  alias Hangman.{Counter, Pass, Words}

  @moduledoc """
  Module provides pass reduction interface for
  reduction engine workers.

  Simply supports fetching word lists, storing
  of word lists and providing the metadata receipt
  """

  @possible_words_left 40

  # READ

  @doc "Fetch word lists data given pass key"
  @spec words(Pass.key()) :: Words.t()
  def words({_id, _game_num, _round_num} = pass_key) do
    # Request words data from Pass Cache
    %Words{} = Pass.Cache.get(pass_key)
  end

  # UPDATE

  @doc """
  Stores word list data and returns a pass receipt

  Filters set of words with regex, tallies reduced word stream, creates new
  Chunk abstraction and stores it back into words pass table.

  If pass size happens to be small enough, will also return
  remaining hangman possible words left to aid in guess selection. 

  Returns pass metadata.
  """

  @spec store(Pass.key(), Words.t(), Enumerable.t()) :: Pass.t()
  def store(pass_key, %Words{} = data, exclusion) do
    # let's collect possible hangman words if pass size is small enough
    # and return them for guessing aid

    {pass_size, last_word, possible_txt} = extract(data)

    # Populate counter object, with new reduced Words
    tally = Counter.add_words(Counter.new(), Words.stream(data), exclusion)

    # Write to cache
    :ok = pass_key |> Pass.increment_key() |> Pass.Cache.put(data)

    # construct pass metadata receipt
    %Pass{size: pass_size, tally: tally, possible: possible_txt, last_word: last_word}
  end

  # PRIVATE HELPERS

  # Extract pass metadata: size, last word, and possible words data

  @spec extract(Words.t()) :: tuple
  defp extract(%Words{} = data) do
    pass_size = Words.count(data)

    {last_word, possible_txt} =
      case pass_size do
        0 ->
          # let higher up handle 
          {"", ""}

        1 ->
          last_word = Words.collect(data, 1)
          # return last word
          {last_word, ""}

        possible when possible > 1 and possible < @possible_words_left ->
          list = Words.collect(data, possible)
          txt = "Possible hangman words left, #{possible} words: #{inspect(list)}"
          {"", txt}

        size when size > 1 ->
          {"", ""}

        size ->
          raise HangmanError, "Invalid pass_size value #{size}"
      end

    {pass_size, last_word, possible_txt}
  end
end
