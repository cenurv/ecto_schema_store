defmodule EctoSchemaStore.Fetch do
  @moduledoc false

  defmacro build(schema, repo) do
    quote do
      defp __preload__(model, []), do: model
      defp __preload__(model, preload) when is_list preload do
        Enum.reduce preload, model, fn(key, acc) -> unquote(repo).preload(acc, key) end
      end
      defp __preload__(model, :all) do
        __preload__ model, schema_associations()
      end
      defp __preload__(model, preload) when is_atom preload do
        __preload__ model, [preload]
      end

      defp __destructure__(model, true), do: destructure(model)
      defp __destructure__(model, false), do: model

      @doc """
      Fetch all records from `#{unquote(schema)}`.
      """
      def all, do: all []

      @doc """
      Fetch all records from `#{unquote(schema)}` filtered by provided fields map.

      Options:

      * `preload`              - Atom or array of atoms with the associations to preload.
      * `destructure`          - Should the record model be converted from its struct to a generic map. Default: `false`
      """
      def all(filters, opts \\ [])
      def all(%Ecto.Query{} = query, opts) do
        preload = Keyword.get opts, :preload, []
        destruct = Keyword.get opts, :destructure, false

        query
        |> unquote(repo).all
        |> __preload__(preload)
        |> __destructure__(destruct)
      end
      def all(filters, opts) do
        preload = Keyword.get opts, :preload, []
        destruct = Keyword.get opts, :destructure, false

        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} ->
            query
            |> unquote(repo).all
            |> __preload__(preload)
            |> __destructure__(destruct)
        end
      end

      @doc """
      Cound the number of records that met that query.
      """
      def count_records(filters)
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
      Fetch a single record from `#{unquote(schema)}` filtered by provided record id or fields map.

      Options:

      * `preload`              - Atom or array of atoms with the associations to preload.
      * `destructure`          - Should the record model be converted from its struct to a generic map. Default: `false`
      """
      def one(filters, opts \\ [])
      def one(id, opts) when is_integer(id) and id > 0, do: one %{id: id}, opts
      def one(%Ecto.Query{} = query, opts) do
        preload = Keyword.get opts, :preload, []
        destruct = Keyword.get opts, :destructure, false

        query
        |> unquote(repo).one
        |> __preload__(preload)
        |> __destructure__(destruct)
      end
      def one(filters, opts) do
        preload = Keyword.get opts, :preload, []
        destruct = Keyword.get opts, :destructure, false 

        case build_query(filters) do
          {:error, _} = error -> error
          {:ok, query} ->
            query
            |> unquote(repo).one
            |> __preload__(preload)
            |> __destructure__(destruct)
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
      Returns true if any records match the provided query filters.
      """
      def exists?(filters), do: count_records(filters) > 0

      @doc """
      Convert the provided record to a generic map and Ecto date or time values to
      Elixir 1.3 equivalents.
      """
      def destructure(record) when is_list record do
        Enum.map record, fn(entry) -> destructure entry end
      end
      def destructure(record), do: convert_model_to_map record

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
