defmodule Hangman.Types do

	defmodule Reduction.Pass do
    defstruct size: 0,
      tally: %{},
      possible: "",
      last_word: ""
  end

  defmodule Game.Round do
  	defstruct seq_no: 0,
      guess: "",
      result_code: nil, 
      status_code: nil, 
      status_text: "",
      pattern: "", 
      final_result: ""
    end
end
