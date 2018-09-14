defmodule EctoSchemaStore.BuildQueries do
  @moduledoc false
  import Ecto.Query

  defp build_keyword_query(query, field_name, {:like, value}) do
    from q in query,
    where: like(field(q, ^field_name), ^value)
  end
  defp build_keyword_query(query, field_name, {:ilike, value}) do
    from q in query,
    where: ilike(field(q, ^field_name), ^value)
  end
  defp build_keyword_query(query, field_name, {:in, value}) do
    from q in query,
    where: field(q, ^field_name) in ^value
  end
  defp build_keyword_query(query, field_name, {:>=, value}) do
    from q in query,
    where: field(q, ^field_name) >= ^value
  end
  defp build_keyword_query(query, field_name, {:>, value}) do
    from q in query,
    where: field(q, ^field_name) > ^value
  end
  defp build_keyword_query(query, field_name, {:<=, value}) do
    from q in query,
    where: field(q, ^field_name) <= ^value
  end
  defp build_keyword_query(query, field_name, {:<, value}) do
    from q in query,
    where: field(q, ^field_name) < ^value
  end
  defp build_keyword_query(query, field_name, {:!=, nil}) do
    from q in query,
    where: not is_nil(field(q, ^field_name))
  end
  defp build_keyword_query(query, field_name, {:==, nil}) do
    from q in query,
    where: is_nil(field(q, ^field_name))
  end
  defp build_keyword_query(query, field_name, {:!=, value}) do
    from q in query,
    where: field(q, ^field_name) != ^value
  end
  defp build_keyword_query(query, field_name, {:==, value}) do
    from q in query,
    where: field(q, ^field_name) == ^value
  end
  defp build_keyword_query(query, field_name, nil) do
    build_keyword_query(query, field_name, {:==, nil})
  end
  defp build_keyword_query(query, field_name, value) do
    build_keyword_query(query, field_name, {:==, value})
  end

  def build_query(%Ecto.Query{} = query, []), do: {:ok, query}
  def build_query(query, []), do: {:ok, from(q in query)} # Schema name only, convert into query to avoid errors.
  def build_query(query, [{key, value} | t]) do
    build_query(build_keyword_query(query, key, value), t)
  end
  def build_query(query, %{} = filters) do
    build_query query, Enum.into(filters, [])
  end


  defmacro build(schema) do
    keys = Macro.expand(schema, __CALLER__).__schema__(:fields)
    associations = Macro.expand(schema, __CALLER__).__schema__(:associations)

    quote do

      def schema_fields, do: unquote(keys)
      def schema_associations, do: unquote(associations)

      defdelegate build_query(query, filters), to: EctoSchemaStore.BuildQueries

      @doc """
      Build an `Ecto.Query` from the provided fields and values map. A keyword list builds
      a query in the order of the provided keys. Maps do not guarantee an order.

      Available fields: `#{inspect unquote(keys)}`
      """
      def build_query(filters \\ [])
      def build_query(filters) do
        build_query unquote(schema), filters
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
