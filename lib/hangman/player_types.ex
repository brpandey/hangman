defmodule Hangman.Player.Types do
  @moduledoc """
  Defines Player types and mapping
  """

  def human, do: :human
  def robot, do: :robot

  def types do
    %{
      :human => %Hangman.Action.Human{},
      :robot => %Hangman.Action.Robot{}
    }
  end
end
