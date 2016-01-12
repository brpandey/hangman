defmodule Hangman.Types do

	defmodule Reduction.Pass do
    defstruct size: 0,
      tally: %{},
      only_word_left: ""
  end

  defmodule Game.Round do
  	defstruct seq_no: 0,
      guess: "",
      result: Nil, 
      status_code: Nil, 
      status_text: "",
      pattern: "", 
      final_result: ""
    end
end