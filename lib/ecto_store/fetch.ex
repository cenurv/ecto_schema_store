defmodule EctoStore.Fetch do
  defmacro build(repo) do
    quote do
      def all do
        case build_query do
          {:error, _} = error -> error
          {:ok, query} -> unquote(repo).all query
        end
      end

      def all(%Ecto.Query{} = query), do: unquote(repo).all query
      def all(%{} = filters) do
        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} -> unquote(repo).all query
        end
      end
      
      def fetch(%Ecto.Query{} = query), do: all query
      def fetch(%{} = filters), do: all filters

      def one(%Ecto.Query{} = query), do: unquote(repo).one query
      def one(%{} = filters) do
        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} -> unquote(repo).one query
        end
      end

      def get(id) when is_integer(id) and id > 0, do: one %{id: id}
    end
  end
end