defmodule Hangman do
  use Application

  @moduledoc  """
  Main `Hangman` application.  
  
  `Usage:
  --name (player id) --type ("human" or "robot") --random (num random secrets, max 10)
  [--secret (hangman word(s)) --baseline] [--log --display]`
  
  or
  
  `Aliase Usage: 
  -n (player id) -t ("human" or "robot") -r (num random secrets, max 10)
  [-s (hangman word(s)) -bl] [-l -d]`
  
  """

  require Logger


  @doc """
  Main `application` callback start method. Calls `Root.Supervisor`
  """

  @callback start(term, Keyword.t) :: Supervisor.on_start
  def start(_type, args) do
		Logger.info "Starting Hangman Application, args: #{inspect args}"
    Root.Supervisor.start_link args
  end
end
