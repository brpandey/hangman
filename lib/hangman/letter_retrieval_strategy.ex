defmodule Hangman.Letter.Retrieval.Strategy do
  alias Hangman.Letter.{Retrieval, Strategy}

  # Letter.Retrieval.Strategy serves as a behavior with one function to implement
  @callback optimal(Strategy.t) :: String.t | no_return
  
  # Only supports one letter retrieval type for the moment
  def select(%Strategy{} = strategy) do
    Retrieval.Common.optimal(strategy)
  end

end
