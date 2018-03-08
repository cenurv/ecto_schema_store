defmodule EctoSchemaStore.Fetch do
  @moduledoc false

  defmacro build(schema, repo) do
    quote do
      defp __preload__(model, preload), do: preload_assocs model, preload

      defp __to_map__(model, true), do: to_map(model)
      defp __to_map__(model, false), do: model

      defp __order_by__(query, nil), do: query
      defp __order_by__(query, order_list) when is_atom order_list do
        __order_by__ query, [order_list]
      end
      defp __order_by__(query, order_list) do
        from m in query,
        order_by: ^order_list
      end

      defp __limit_to_first__(results) when is_list results do
        Enum.at results, 0
      end
      defp __limit_to_first__([]) do
        nil
      end
      defp __limit_to_first__(results), do: results

      @doc """
      Fetch all records from `#{unquote(schema)}`.
      """
      def all, do: all []

      @doc """
      Fetch all records from `#{unquote(schema)}` filtered by provided fields map.

      Options:

      * `preload`              - Atom or array of atoms with the associations to preload.
      * `to_map`               - Should the record model be converted from its struct to a generic map. Default: `false`
      * `order_by`             - Order the results by a the provided keyword list.
      """
      def all(filters, opts \\ [])
      def all(%Ecto.Query{} = query, opts) do
        preload = Keyword.get opts, :preload, []
        destruct = Keyword.get opts, :destructure, false
        to_map = Keyword.get opts, :to_map, false
        to_map = destruct || to_map
        order_list = Keyword.get opts, :order_by, nil

        query
        |> __order_by__(order_list)
        |> unquote(repo).all
        |> __preload__(preload)
        |> __to_map__(to_map)
      end
      def all(filters, opts) do
        preload = Keyword.get opts, :preload, []
        destruct = Keyword.get opts, :destructure, false
        to_map = Keyword.get opts, :to_map, false
        to_map = destruct or to_map
        order_list = Keyword.get opts, :order_by, nil

        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} ->
            query
            |> __order_by__(order_list)
            |> unquote(repo).all
            |> __preload__(preload)
            |> __to_map__(to_map)
        end
      end

      @doc """
      Cound the number of records that met that query.
      """
      def count_records(filters \\ [])
      def count_records(%Ecto.Query{} = query) do
        query =
          from q in query,
          select: count(q.id)

        unquote(repo).one(query)
      end
      def count_records(filters) do
        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} -> count_records query
        end
      end

      @doc """
      Fetch a single record from `#{unquote(schema)}` filtered by provided record id or fields map. If multiple
      records are returned. Will return the first record. This operation will not return an error if more than
      one record is found.

      Options:

      * `preload`              - Atom or array of atoms with the associations to preload.
      * `to_map`               - Should the record model be converted from its struct to a generic map. Default: `false`
      * `order_by`             - Order the results by a the provided keyword list.
      """
      def one(filters, opts \\ [])
      def one(nil, _opts), do: nil
      def one(id, opts) when is_binary(id), do: one String.to_integer(id), opts
      def one(id, opts) when is_integer(id) and id > 0, do: one %{id: id}, opts
      def one(%Ecto.Query{} = query, opts) do
        preload = Keyword.get opts, :preload, []
        destruct = Keyword.get opts, :destructure, false
        to_map = Keyword.get opts, :to_map, false
        to_map = destruct or to_map
        order_list = Keyword.get opts, :order_by, nil

        query
        |> __order_by__(order_list)
        |> unquote(repo).all
        |> __limit_to_first__
        |> __preload__(preload)
        |> __to_map__(to_map)
      end
      def one(filters, opts) do
        preload = Keyword.get opts, :preload, []
        destruct = Keyword.get opts, :destructure, false
        to_map = Keyword.get opts, :to_map, false
        to_map = destruct or to_map
        order_list = Keyword.get opts, :order_by, nil

        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} ->
            query
            |> __order_by__(order_list)
            |> unquote(repo).all
            |> __limit_to_first__
            |> __preload__(preload)
            |> __to_map__(to_map)
        end
      end

      @doc """
      Reloads a single record for `#{unquote(schema)}` from the database.
      """
      def refresh(record), do: one record.id

      @doc """
      Preloads child associations.
      """
      def preload_assocs(record, :all), do: preload_assocs(record, schema_associations())
      def preload_assocs(record, fields) when is_list fields do
        unquote(repo).preload(record, fields)
      end
      def preload_assocs(record, field), do: preload_assocs(record, [field])

      @doc """
      Helper to order a preload by a provided Ecto repo order by value.

      ```elixir
      store.preload_assocs(model, [field: order_preload_by(:name)])
      ```

      The same as:

      ```elixir
      import Ecto.Query, only: [from: 2]
      store.preload_assocs(model, [field: (from(s in Schema, order_by: s.name))])
      ```
      """
      def order_preload_by(order_params) do
        order_by build_query!(), ^order_params
      end

      @doc """
      Returns true if any records match the provided query filters.
      """
      def exists?(filters), do: count_records(filters) > 0

      @doc """
      Convert the provided record to a generic map and Ecto date or time values to
      Elixir 1.3 equivalents. Replaces `destructure`.
      """
      def to_map(record) when is_list record do
        Enum.map record, fn(entry) -> to_map entry end
      end
      def to_map(record), do: convert_model_to_map record

      defp convert_model_to_map(model, convert_ecto \\ true)
      defp convert_model_to_map(nil, _convert_ecto), do: nil
      defp convert_model_to_map(%{} = model, convert_ecto) do
        keys = List.delete Map.keys(model), :__meta__
        keys = List.delete keys, :__struct__

        key_values = for key <- keys do
          convert_value key, Map.get(model, key), convert_ecto
        end

        Enum.into key_values, %{}
      end
      defp convert_model_to_map(value, _convert_ecto), do: value

      defp convert_value(key, %Ecto.Association.NotLoaded{}, true), do: {key, :not_loaded}
      defp convert_value(key, %Ecto.Time{} = value, true), do: {key, value |> Ecto.Time.to_erl |> Time.from_erl!}
      defp convert_value(key, %Ecto.Date{} = value, true), do: {key, value |> Ecto.Date.to_erl |> Date.from_erl!}
      defp convert_value(key, %Ecto.DateTime{} = value, true), do: {key, value |> Ecto.DateTime.to_erl |> NaiveDateTime.from_erl!}
      defp convert_value(key, %DateTime{} = value, true), do: {key, value}
      defp convert_value(key, %Date{} = value, true), do: {key, value}
      defp convert_value(key, %Time{} = value, true), do: {key, value}
      defp convert_value(key, %NaiveDateTime{} = value, true), do: {key, value}
      defp convert_value(key, %{} = value, convert_ecto), do: {key, convert_model_to_map(value, convert_ecto)}
      defp convert_value(key, [%{} = h | t], convert_ecto) do
        first = convert_model_to_map(h, convert_ecto)

        rest = for entry <- t do
          convert_model_to_map(entry, convert_ecto)
        end

        {key, [first | rest]}
      end
      defp convert_value(key, value, _convert_ecto), do: {key, value}
    end
  end
end
