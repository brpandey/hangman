defmodule Hangman.Player do
  @type id :: String.t
  @type key :: {id :: String.t, player_pid :: pid} # Used as game key
end


