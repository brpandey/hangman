defmodule Hangman.Player do
  
  # The Player ID needs to be unique during multiple concurrent game play
  # Async testing of hangman games should use different player ids

  @type id :: String.t | {id :: String.t, shard_no :: pos_integer}
  @type key :: {id :: String.t, player_pid :: pid} # Used as game key
end


