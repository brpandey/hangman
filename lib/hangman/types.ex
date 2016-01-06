defmodule Hangman.Types do
	defmodule WordPass do
    defstruct pass_size: 0,
      pass_tally: Nil,
      pass_only_word_left: ""
  end
end