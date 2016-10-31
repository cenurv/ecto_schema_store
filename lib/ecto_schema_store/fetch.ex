defmodule EctoSchemaStore.Fetch do
  @moduledoc false

  defmacro build(schema, repo) do
    quote do
      @doc """
      Fetch all records from `#{unquote(schema)}`.
      """
      def all do
        case build_query do
          {:error, _} = error -> error
          {:ok, query} -> unquote(repo).all query
        end
      end

      @doc """
      Fetch all records from `#{unquote(schema)}` filtered by provided fields map.
      """
      def all(%Ecto.Query{} = query), do: unquote(repo).all query
      def all(filters) do
        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} -> unquote(repo).all query
        end
      end

      @doc """
      Fetch a single record from `#{unquote(schema)}` filtered by provided record id or fields map.
      """
      def one(id) when is_integer(id) and id > 0, do: one %{id: id}
      def one(%Ecto.Query{} = query), do: unquote(repo).one query
      def one(filters) do
        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} -> unquote(repo).one query
        end
      end
    end
  end
end