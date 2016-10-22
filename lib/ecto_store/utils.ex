defmodule EctoStore.Utils do
  def remove_from_map(map, key) do
    case Map.pop(map, key) do
      {_, result} -> result
    end
  end

  def keys(schema) do
    impl = struct schema
    keys = Map.keys impl

    ignore = [:__struct__, :__meta__]

    Enum.filter keys, &((&1 in ignore) == false)    
  end
end