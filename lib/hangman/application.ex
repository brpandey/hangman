defmodule Root.Application do
  use Application

  @moduledoc """
  Main hangman application callback module.  
  Invokes root level supervisor
  """

  require Logger


  @doc """
  Main application start method
  """

  @spec start(term, Keyword.t) :: Supervisor.on_start
  def start(_type, args) do
		Logger.info "Starting Hangman Application, args: #{inspect args}"
    Root.Supervisor.start_link args
  end
end
