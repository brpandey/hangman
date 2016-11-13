defmodule Hangman.Simple.Registry.Test do
  use ExUnit.Case, async: true

  alias Hangman.Simple.Registry


  describe "registry create" do
    test "setup simple registry" do

      id = "yellow42"

      {:ok, pid} = Agent.start_link(fn -> %{data: "yellow fellow hello"} end)

      key = {id, pid}

      registry = Registry.new |> Registry.add_key(key)

      assert {id, pid} == registry |> Registry.key(id)
      assert {id, pid} == registry |> Registry.key(pid)
    end

    test "setup registry with nil id" do

      id = nil

      {:ok, pid} = Agent.start_link(fn -> %{data: "yellow fellow hello"} end)

      key = {id, pid}

      registry = Registry.new |> Registry.add_key(key)

      assert catch_error(registry |> Registry.key(id))
      assert nil == registry |> Registry.key(pid)
    end


    test "setup registry with nil pid" do

      id = "yellow42"

      pid = nil

      key = {id, pid}

      registry = Registry.new |> Registry.add_key(key)

      assert nil == registry |> Registry.key(id)
      assert catch_error(registry |> Registry.key(pid))
    end
  end



  describe "registry update" do

    test "set value and fetch it" do
 
      id = "yellow42"
      value = 10
      
      {:ok, pid} = Agent.start_link(fn -> %{} end) # start up a pid
      
      key = {id, pid}
      
      registry = Registry.new |> Registry.add_key(key) |> Registry.update(key, value)
      
      assert ^value = registry |> Registry.value(key)
      
    end

    test "set value and fetch a non-existent id but same pid" do
 
      id1 = "yellow42"
      id2 = "yellow43"

      value = 10
      
      {:ok, pid} = Agent.start_link(fn -> %{} end) # start up a pid
      
      key1 = {id1, pid}
      key2 = {id2, pid}
      
      registry = Registry.new |> Registry.add_key(key1) |> Registry.update(key1, value)
      
      assert nil == registry |> Registry.value(key2)
      
    end

    test "set value and fetch a non-existent pid but same id" do
 
      id = "yellow42"

      value = 10
      
      {:ok, pid1} = Agent.start_link(fn -> %{} end) # start up a pid
      {:ok, pid2} = Agent.start_link(fn -> %{} end) # start up a pid

      key1 = {id, pid1}
      key2 = {id, pid2}
      
      registry = Registry.new |> Registry.add_key(key1) |> Registry.update(key1, value)
      
      assert nil == registry |> Registry.value(key2)      
    end

  end

  describe "registry delete" do

    test "remove value from registry, upon re-access get nil" do

      id1 = "yellow42"
      id2 = "yellow43"

      value = 10
      
      {:ok, pid} = Agent.start_link(fn -> %{} end) # start up a pid

      key1 = {id1, pid}
      key2 = {id2, pid}

      # add key and set value
      registry = Registry.new |> Registry.add_key(key1) |> Registry.update(key1, value)
      assert ^value = registry |> Registry.value(key1)

      # try to delete non-existent key
      assert catch_error(registry |> Registry.remove(:value, key2)) == 
        %HangmanError{message: "Can't remove value state that doesn't exist"}

      # delete key then try to access it again
      assert nil == registry |> Registry.remove(:value, key1) |> Registry.value(key1)
    end

    test "remove from actives, get nil when access value, re-add key and get value " do

      id1 = "yellow42"
      id2 = "yellow43"

      value = 10
      
      {:ok, pid1} = Agent.start_link(fn -> %{} end) # start up a pid

      key1 = {id1, pid1}
      key2 = {id2, pid1}

      # add key and set value
      registry = Registry.new |> Registry.add_key(key1) |> Registry.update(key1, value)
      assert ^value = registry |> Registry.value(key1)

      # try to delete non-existent key but same pid
      assert catch_error(registry |> Registry.remove(:active, key2)) == 
        %HangmanError{message: "pid found, but different id. Strange!"}

      # delete key from actives
      # then try to access it's value
      # since no longer active should return nil
      registry = registry |> Registry.remove(:active, key1)

      assert nil == registry |> Registry.value(key1)

      # add key back to actives and the value should be available again
      assert ^value = registry |> Registry.add_key(key1) |> Registry.value(key1)
    end


  end


end
