defmodule Hangman.Pass.Cache.Test do
  use ExUnit.Case

  require Logger

  alias Hangman.{Pass, Chunks}

  setup_all do
    IO.puts "Pass Cache Test"
    :ok
  end


  setup _context do
    cache_pid = 
      case Pass.Cache.start_link() do
        {:ok, pid} ->
          pid
        {:error, {:already_started, pid}} -> 
          pid
      end

    cache_writer_pid = 
      case Pass.Cache.Writer.start_link() do
        {:ok, pid} ->
          pid
        {:error, {:already_started, pid}} -> 
          pid
      end

    on_exit fn -> 
      # Ensure the pass servers are shutdown with non-normal reason
      Process.exit(cache_pid, :shutdown)
      Process.exit(cache_writer_pid, :shutdown)
      
      # Wait until the servers are dead
      cache_ref = Process.monitor(cache_pid)
      cache_writer_ref = Process.monitor(cache_writer_pid)

      assert_receive {:DOWN, ^cache_ref, _, _, _}
      assert_receive {:DOWN, ^cache_writer_ref, _, _, _}
    end

    :ok
  end


  test "pass get and delete" do
    key = {"francois", 1, 3}

    # error read
    assert :error = Pass.Cache.get(key)

    # put
    chunks = Chunks.new(123)
    Pass.Cache.put(key, chunks)

    # read (read returns value and deletes it in ets)
    assert ^chunks = Pass.Cache.get(key)

    # error delete
    assert :error = Pass.Cache.delete(key)

    # error read
    assert :error = Pass.Cache.get(key)

    Pass.Cache.Writer.stop
    Pass.Cache.stop

    :ok
  end


  test "pass delete and get" do
    key = {"francois", 1, 4}

    # error read
    assert :error = Pass.Cache.get(key)

    # put
    chunks = Chunks.new(456)
    Pass.Cache.put(key, chunks)

    # delete then error read
    assert :ok = Pass.Cache.delete(key)

    assert :error = Pass.Cache.get(key)

    Pass.Cache.Writer.stop
    Pass.Cache.stop

    :ok
  end


end
