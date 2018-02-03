defmodule Hangman.Game.Event.Manager.Test do
  use ExUnit.Case, async: false

  alias Hangman.{Player, Game.Event}

  setup_all do
    IO.puts("Game Event Manager Test")

    case Event.Manager.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    case Player.Logger.Supervisor.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    case Player.Alert.Supervisor.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  test "inital events server setup" do
    key = "polarbear"

    # Get event server pid next
    {:ok, _lpid} = Player.Logger.Supervisor.start_child(key)
    {:ok, _apid} = Player.Alert.Supervisor.start_child(key, nil)

    Event.Manager.async_notify({:register, key, {1, 8}})

    payload = {{:guess_letter, "a"}, 1}
    Event.Manager.async_notify({:guess, key, payload})

    payload = {1, 1, "my head is warm"}
    Event.Manager.async_notify({:status, key, payload})

    payload = {{:guess_letter, "f"}, 1}
    Event.Manager.async_notify({:guess, key, payload})

    payload = {1, 2, "three blind mice"}
    Event.Manager.async_notify({:status, key, payload})

    payload = {{:guess_letter, "e"}, 1}
    Event.Manager.async_notify({:guess, key, payload})

    payload = {1, 3, "geronimo it's snowing"}
    Event.Manager.async_notify({:status, key, payload})

    payload = {{:guess_letter, "h"}, 1}
    Event.Manager.async_notify({:guess, key, payload})

    payload = {1, 4, "equidistant points"}
    Event.Manager.async_notify({:status, key, payload})

    payload = {{:guess_letter, "l"}, 1}
    Event.Manager.async_notify({:guess, key, payload})

    payload = {1, 5, "invisible sun"}
    Event.Manager.async_notify({:status, key, payload})

    payload = {{:guess_letter, "k"}, 1}
    Event.Manager.async_notify({:guess, key, payload})

    payload = {1, 6, "folk songs"}
    Event.Manager.async_notify({:status, key, payload})

    payload = "game over summary goes here"
    Event.Manager.async_notify({:finished, key, payload})
  end
end
