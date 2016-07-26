defmodule Hangman.Dictionary.Transformer do

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.{Transformer}

  defstruct enumerable: %{}, kind: nil

  @moduledoc """
  The original `Dictionary` file is transformed into 
  intermediary representations. Given an original dictionary file f1, this 
  file may be transformed a few times until it is suitable to be loaded 
  into `ETS`.  E.g. `f1` -> `f2` -> `f3` -> `f4`.

  This sequence of transforms (t1, t2, t3, t4) is done initially and does
  not need to be repeated unless the original file changes.

  Dictionary word load time is only determined by the last transformed file `f4`, 
  which is optimized for `ETS` load.
  """

  def new(kind) when is_atom(kind) do

    # Store the transform run functions by order
    # First we sort, then group, then chunk

    transforms = Map.put(%{}, 1, &Dictionary.File.Sorter.run/1)
    transforms = Map.put(transforms, 2, &Dictionary.File.Grouper.run/1)
    transforms = Map.put(transforms, 3, &Dictionary.File.Chunker.run/1)

    %Transformer{kind: kind, enumerable: transforms}
  end


  # Delay the actual function invocation to this method
  # We are making the assumption that the enumerable will be 
  # processed from keys 1 to 3
  # NOTE: Need stronger guarentee check
  def run(%Transformer{} = state) do
    Enum.reduce(state.enumerable, "", fn ({_key, func}, _acc) -> 
      func.(state.kind)
    end)

  end

end
