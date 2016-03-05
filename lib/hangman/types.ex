defmodule Hangman.Types do
  @moduledoc """
  Catch all module for types used within Hangman application 
  not already defined within modules
  """

  defmodule Guess do
    @moduledoc """
    Defines guess type format
    """

    @type t :: {:guess_letter, String.t} | {:guess_word, String.t}
  end

  defmodule Reduction.Key do
    @moduledoc """
    Defines reduction key type format
    """

    @type t :: ( [{:game_start, boolean}, {:secret_length, pos_integer}] ) |
    ( [{:incorrect_letter, l :: String.t}, {:guessed_letters, MapSet.t}, {:regex_match_key, Regex.t}] ) | 
    ( [{:correct_letter, l :: String.t}, {:guessed_letters, MapSet.t}, {:regex_match_key, Regex.t}] )
    
  end

	defmodule Reduction.Pass do
    @moduledoc """
    Defines reduction pass and pass type
    """

    defstruct size: 0, tally: %{}, possible: "", last_word: ""
    
    @type t :: %__MODULE__{}

    defmodule Key do
      @moduledoc """
      Define reduction pass key type format
      """

      @type t :: {id :: String.t, game_no :: pos_integer, round_no :: pos_integer}
    end
  end

  defmodule Game.Round do
    @moduledoc """
    Defines game round and game round type
    """

  	defstruct seq_no: 0,
    guess: "",
    result_code: nil, 
    status_code: nil, 
    status_text: "",
    pattern: "", 
    final_result: ""
    
    @type t :: %__MODULE__{} 
  end
end
