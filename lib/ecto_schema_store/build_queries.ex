defmodule EctoSchemaStore.BuildQueries do
  @moduledoc false

  defmacro build_ecto_query(query, :is_nil, key) do
    quote do
      from q in unquote(query),
      where: is_nil(field(q, ^unquote(key)))
    end
  end
  defmacro build_ecto_query(query, :not_nil, key) do
    quote do
      from q in unquote(query),
      where: not is_nil(field(q, ^unquote(key)))
    end
  end
  defmacro build_ecto_query(query, :eq, key, value) do
    quote do
      from q in unquote(query),
      where: field(q, ^unquote(key)) == unquote(value)
    end
  end
  defmacro build_ecto_query(query, :not, key, value) do
    quote do
      from q in unquote(query),
      where: field(q, ^unquote(key)) != unquote(value)
    end
  end
  defmacro build_ecto_query(query, :lt, key, value) do
    quote do
      from q in unquote(query),
      where: field(q, ^unquote(key)) < unquote(value)
    end
  end
  defmacro build_ecto_query(query, :lte, key, value) do
    quote do
      from q in unquote(query),
      where: field(q, ^unquote(key)) <= unquote(value)
    end
  end
  defmacro build_ecto_query(query, :gt, key, value) do
    quote do
      from q in unquote(query),
      where: field(q, ^unquote(key)) > unquote(value)
    end
  end
  defmacro build_ecto_query(query, :gte, key, value) do
    quote do
      from q in unquote(query),
      where: field(q, ^unquote(key)) >= unquote(value)
    end
  end
  defmacro build_ecto_query(query, :in, key, value) do
    quote do
      from q in unquote(query),
      where: field(q, ^unquote(key)) in unquote(value)
    end
  end

  defmacro build(schema) do
    keys = EctoSchemaStore.Utils.keys(Macro.expand(schema, __CALLER__), false)
    assocs = EctoSchemaStore.Utils.keys(Macro.expand(schema, __CALLER__), true)

    quote do
      defp build_keyword_query(query, field_name, {:in, value}) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :in, field_name, ^value)}
      end
      defp build_keyword_query(query, field_name, {:>=, value}) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :gte, field_name, ^value)}
      end
      defp build_keyword_query(query, field_name, {:>, value}) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :gt, field_name, ^value)}
      end
      defp build_keyword_query(query, field_name, {:<=, value}) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :lte, field_name, ^value)}
      end
      defp build_keyword_query(query, field_name, {:<, value}) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :lt, field_name, ^value)}
      end
      defp build_keyword_query(query, field_name, {:!=, nil}) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :not_nil, field_name)}
      end
      defp build_keyword_query(query, field_name, {:==, nil}) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :is_nil, field_name)}
      end
      defp build_keyword_query(query, field_name, {:!=, value}) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :not, field_name, ^value)}
      end
      defp build_keyword_query(query, field_name, {:==, value}) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :eq, field_name, ^value)}
      end
      defp build_keyword_query(query, field_name, nil) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :is_nil, field_name)}
      end
      defp build_keyword_query(query, field_name, value) do
        {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :eq, field_name, ^value)}
      end

      def schema_fields, do: unquote(keys)
      def schema_associations, do: unquote(assocs)

      defp build_query(query, []), do: {:ok, query}
      defp build_query(query, [{key, value} | t]) do
        case build_keyword_query(query, key, value) do
          {:ok, query} -> build_query query, t
          {:error, _message} = error -> error
        end
      end
      defp build_query(query, %{} = filters) do
        build_query query, Enum.into(filters, [])
      end

      @doc """
      Build an `Ecto.Query` from the provided fields and values map. A keyword list builds
      a query in the order of the provided keys. Maps do not guarantee an order.

      Available fields: `#{inspect unquote(keys)}`
      """
      def build_query(filters \\ [])
      def build_query(filters) do
        build_query unquote(schema), alias_filters(filters)
      end

      @doc """
      Build an `Ecto.Query` from the provided fields and values map. Returns the values or throws an error.

      Available fields: `#{inspect unquote(keys)}`
      """
      def build_query!(filters \\ [])
      def build_query!(filters) do
        case build_query(filters) do
          {:error, reason} -> throw reason
          {:ok, query} -> query
        end
      end
    end
  end  
end
