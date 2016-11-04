defmodule Hangman.Pass do
  @moduledoc """
  Module defines types `Pass.key` and `Pass.t`

  Returns result of pass runs as distinguished by initial
  `:start` or subsequent `:guessing` modes.

  Pass data is a group of the pass size, the letter frequency tally, 
  and relevant data on final word information.

  Given a new `Hangman` game, initially the words pass is the size of all words
  in the dictionary of secret length k.  As each round proceeds, this is reduced by the 
  `Hangman` pattern sequence.  It is these remaining possible word set instances
  that are stored in the cache.

  After each player has made their `Hangman` round guess, the resultant reduced
  words `pass` data is stored into the `Pass.Cache` for access on the 
  subsequent round.  The expired `pass` data from stale rounds is subsequently 
  removed from the `cache`.
  """

  alias Hangman.{Reduction, Pass, Chunks, Counter, Dictionary}

  defstruct size: 0, tally: %{}, possible: "", last_word: ""

  @typedoc "Defines word `pass` type"
  @type t :: %__MODULE__{}

  @typedoc "Defines word `pass` key type"
  @type key  :: {id :: (String.t | tuple), 
                 game_num :: non_neg_integer, 
                 round_num :: non_neg_integer}  


  @spec increment_key(Pass.key) :: Pass.key
  def increment_key({id, game_num, round_num} = _key) do
    {id, game_num, round_num + 1}
  end


  @doc """
  Result routine retrieves the `pass` size, tally, possible words, 
  and other data given these cache `keys`. Relies on either the Dictionary
  Cache or the Reduction Engine to compute new pass data

    * `:start` - this is the initial game start `pass`, so we 
    request the data from the `Dictionary.Cache`.  The data is stored into 
    the `Pass.Cache` via `Pass.Cache.Writer.write/2`. Returns `pass` data type.

    * `:guessing` - retrieves the pass data from the last 
    player round and relies on `Reduction.Engine.reduce/3` to reduce the possible
    `Hangman` words set with `reduce_key`.  When the reduction is finished, we 
    write the data back to the `Pass.Cache` and return the new `pass` data.
  """


  @spec result(atom, pass_key :: Pass.key, reduce_key :: Reduction.key) :: {Pass.key, Pass.t}

  def result(:start, {id, game_no, round_no} = pass_key, reduce_key)
  when (is_binary(id) or is_tuple(id)) 
  and is_number(game_no) and is_number(round_no) do

    # Asserts
    {:ok, true} = Keyword.fetch(reduce_key, :start)
    {:ok, length_key}  = Keyword.fetch(reduce_key, :secret_length)
    
    # Since this is the first pass, grab the words and tally from
    # the Dictionary Cache

    # Subsequent round lookups will be from the pass table

    chunks = %Chunks{} = Dictionary.lookup(:chunks, length_key)
    tally = %Counter{} = Dictionary.lookup(:tally, length_key)

    pass_size = Chunks.count(chunks)
    pass_info = %Pass{ size: pass_size, tally: tally, last_word: ""}

    # Store pass info into ets table for round 2 (next pass)
    # Allow writer engine to execute (and distribute) as necessary

    next_pass_key = Pass.increment_key(pass_key)
    Pass.Cache.put(next_pass_key, chunks)
  
    {pass_key, pass_info}
  end


  def result(:guessing, {id, game_no, round_no} = pass_key, reduce_key)
  when (is_binary(id) or is_tuple(id)) and is_number(game_no) and is_number(round_no) do
    
    {:ok, exclusion_set} = Keyword.fetch(reduce_key, :guessed_letters)
    {:ok, regex_key} = Keyword.fetch(reduce_key, :regex_match_key)
  
    # Send pass and reduce information off to Engine server
    # to execute (and distribute) as appropriate
    # operation subsequently writes back to pass_cache
    pass_info = Reduction.Engine.reduce(pass_key, regex_key, exclusion_set)

    {pass_key, pass_info}
  end

  @doc """
  Removes pass key from ets
  """

  @spec delete(key) :: :ok
  def delete({id, game_no, round_no} = pass_key) when 
  (is_binary(id) or is_tuple(id)) 
  and is_number(game_no) and is_number(round_no) do
    Pass.Cache.delete(pass_key)
  end

end
