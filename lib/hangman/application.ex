defmodule Hangman.Application do
  use Application

  @moduledoc """
  Main application callback module
  """

  require Logger


  @doc """
  Main application start method
  """

  @spec start(term, Keyword.t) :: Supervisor.on_start
  def start(_type, args) do
		Logger.info "Starting Hangman Application, args: #{inspect args}"
    Hangman.Supervisor.start_link args
  end
end
