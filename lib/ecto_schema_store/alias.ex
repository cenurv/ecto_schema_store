defmodule EctoSchemaStore.Alias do
  @moduledoc false

  defmacro build do
    quote do
      defp alias_filters(filters), do: filters

      defoverridable [alias_filters: 1]
    end
  end

  defmacro alias_fields(keywords) do
    quote do
      defp alias_filters(filters) do
        aliases = unquote(keywords)

        Enum.reduce Keyword.keys(aliases), filters, fn(key, acc) ->
          if acc[key] do
            acc
            |> Map.put(aliases[key], acc[key])
            |> Map.delete(key)
          else
            acc
          end
        end
      end
    end
  end
end
