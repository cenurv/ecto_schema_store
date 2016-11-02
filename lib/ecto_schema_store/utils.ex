defmodule EctoSchemaStore.Utils do
  @moduledoc false

  def remove_from_map(map, key) do
    case Map.pop(map, key) do
      {_, result} -> result
    end
  end

  defp is_assoc(%Ecto.Association.NotLoaded{}), do: true
  defp is_assoc(_), do: false

  def keys(schema, only_assocs \\ false) do
    impl = struct schema
    keys = Map.keys impl

    ignore = [:__struct__, :__meta__]

    Enum.filter keys, fn(key) ->
      default_value = Map.get(impl, key)
      if not only_assocs do
        !is_assoc(default_value) and (key in ignore) == false
      else
        is_assoc(default_value) 
      end
    end
  end
end
