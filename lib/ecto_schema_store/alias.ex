defmodule EctoSchemaStore.Alias do
  @moduledoc false

  defmacro build do
    quote do
      def alias_filters(filters), do: generalize_keys(filters)

      defp generalize_keys(entries) when is_list entries do
        for entry <- entries do
          generalize_keys entry
        end
      end
      defp generalize_keys(%{} = filters) do
        for {key, value} <- filters, into: %{} do
          key =
            case is_atom(key) do
              true -> key
              false -> String.to_atom(key)
            end

          cond do
            is_map(value) and not Map.has_key?(value, :__struct__) -> {key, generalize_keys(value)}
            is_list(value) -> {key, generalize_keys(value)}
            true -> {key, value}
          end
        end
      end
      defp generalize_keys(value), do: value

      defoverridable [alias_filters: 1]
    end
  end

  defmacro alias_fields(keywords) do
    quote do
      def alias_filters(filters) when is_list filters do
        aliases = unquote(keywords)

        for {key, value} <- filters do
          new_key = Keyword.get aliases, key, nil

          if new_key do
            {new_key, value}
          else
            {key, value}
          end
        end
      end
      def alias_filters(filters) do
        filters = generalize_keys(filters)
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
