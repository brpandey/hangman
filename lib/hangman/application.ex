defmodule Hangman.Application do
  use Application

  def start(_, _) do
    Hangman.Supervisor.start_link
  end
end
