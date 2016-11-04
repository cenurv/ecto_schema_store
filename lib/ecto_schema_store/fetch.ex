defmodule EctoSchemaStore.Fetch do
  @moduledoc false

  defmacro build(schema, repo) do
    quote do
      defp __preload__(model, []), do: model
      defp __preload__(model, preload) when is_list preload do
        Enum.reduce preload, model, fn(key, acc) -> unquote(repo).preload(acc, key) end
      end
      defp __preload__(model, :all) do
        __preload__ model, schema_associations
      end
      defp __preload__(model, preload) when is_atom preload do
        __preload__ model, [preload]
      end

      @doc """
      Fetch all records from `#{unquote(schema)}`.
      """
      def all, do: all %{}

      @doc """
      Fetch all records from `#{unquote(schema)}` filtered by provided fields map.

      Options:

      * `preload`              - Atom or array of atoms with the associations to preload.
      """
      def all(filters, opts \\ [])
      def all(%Ecto.Query{} = query, opts) do
        preload = Keyword.get opts, :preload, []
        __preload__(unquote(repo).all(query), preload)
      end
      def all(filters, opts) do
        preload = Keyword.get opts, :preload, []

        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} -> __preload__(unquote(repo).all(query), preload)
        end
      end

      @doc """
      Fetch a single record from `#{unquote(schema)}` filtered by provided record id or fields map.

      Options:

      * `preload`              - Atom or array of atoms with the associations to preload.      
      """
      def one(filters, opts \\ [])
      def one(id, opts) when is_integer(id) and id > 0, do: one %{id: id}, opts
      def one(%Ecto.Query{} = query, opts) do
        preload = Keyword.get opts, :preload, []
        __preload__(unquote(repo).one(query), preload)
      end
      def one(filters, opts) do
        preload = Keyword.get opts, :preload, []

        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} -> __preload__(unquote(repo).one(query), preload)
        end
      end
    end
  end
end