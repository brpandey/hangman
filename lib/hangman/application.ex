defmodule Hangman.Application do
  use Application

  require Logger

  def start(_type, args) do
		Logger.info "Starting Hangman Application, args: #{inspect args}"
    Hangman.Supervisor.start_link args
  end
end
