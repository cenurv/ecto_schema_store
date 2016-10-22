defmodule EctoStore.Utils do
  def remove_from_map(map, key) do
    case Map.pop(map, key) do
      {_, result} -> result
    end
  end
end