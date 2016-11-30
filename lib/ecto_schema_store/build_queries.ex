defmodule EctoSchemaStore.BuildQueries do
  @moduledoc false

  defmacro build_ecto_query(query, :is_nil, key) do
    key = Code.string_to_quoted! "q.#{key}"

    quote do
      from q in unquote(query),
      where: is_nil(unquote(key))
    end
  end
  defmacro build_ecto_query(query, :not_nil, key) do
    key = Code.string_to_quoted! "q.#{key}"

    quote do
      from q in unquote(query),
      where: not is_nil(unquote(key))
    end
  end

  defmacro build_ecto_query(query, :eq, key, value) do
    key = Code.string_to_quoted! "q.#{key}"

    quote do
      from q in unquote(query),
      where: unquote(key) == unquote(value)
    end
  end
  defmacro build_ecto_query(query, :not, key, value) do
    key = Code.string_to_quoted! "q.#{key}"

    quote do
      from q in unquote(query),
      where: unquote(key) != unquote(value)
    end
  end
  defmacro build_ecto_query(query, :lt, key, value) do
    key = Code.string_to_quoted! "q.#{key}"

    quote do
      from q in unquote(query),
      where: unquote(key) < unquote(value)
    end
  end
  defmacro build_ecto_query(query, :lte, key, value) do
    key = Code.string_to_quoted! "q.#{key}"

    quote do
      from q in unquote(query),
      where: unquote(key) <= unquote(value)
    end
  end
  defmacro build_ecto_query(query, :gt, key, value) do
    key = Code.string_to_quoted! "q.#{key}"

    quote do
      from q in unquote(query),
      where: unquote(key) > unquote(value)
    end
  end
  defmacro build_ecto_query(query, :gte, key, value) do
    key = Code.string_to_quoted! "q.#{key}"

    quote do
      from q in unquote(query),
      where: unquote(key) >= unquote(value)
    end
  end
  defmacro build_ecto_query(query, :in, key, value) do
    key = Code.string_to_quoted! "q.#{key}"

    quote do
      from q in unquote(query),
      where: unquote(key) in unquote(value)
    end
  end

  defmacro build(schema) do
    keys = EctoSchemaStore.Utils.keys(Macro.expand(schema, __CALLER__), false)
    assocs = EctoSchemaStore.Utils.keys(Macro.expand(schema, __CALLER__), true)

    getters =
      quote do
        defp get_field_map(lexical_atom, values) do
          fields =
            lexical_atom
            |> Atom.to_string
            |> String.split("_and_")
            |> Enum.map(&String.to_atom(&1))

          if length(fields) == length(values) do
            field_map =
              Enum.reduce Enum.with_index(fields), %{}, fn({field, index}, acc) ->
                Map.put acc, field, Enum.at(values, index)
              end

            {:ok, field_map}
          else
            {:error, "Field and values list must have the same number of entries."}
          end
        end

        @doc """
        Get all records matching the atom with the schema field names and the list of values.

        ```elixir
        get_all_by :name_and_email, ["Bob", "bob@nowhere.test"]
        ```
        """
        def get_all_by(lexical_atom, values) do
          case get_field_map(lexical_atom, values) do
            {:error, _} = error -> error
            {:ok, field_map} -> all(field_map)
          end
        end

        @doc """
        Get a single record matching the atom with the schema field names and the list of values.

        ```elixir
        get_by :name_and_email, ["Bob", "bob@nowhere.test"]
        ```
        """
        def get_by(lexical_atom, values) do
          case get_field_map(lexical_atom, values) do
            {:error, _} = error -> error
            {:ok, field_map} -> one(field_map)
          end
        end
      end

    functions =
      for key <- keys do
        map_entry = Code.string_to_quoted! "%{#{key}: _}"
        eq_map_entry = Code.string_to_quoted! "%{#{key}: {:==, _}}"
        not_map_entry = Code.string_to_quoted! "%{#{key}: {:!=, _}}"
        is_nil_map_entry = Code.string_to_quoted! "%{#{key}: :nil}"
        is_nil_atom_map_entry = Code.string_to_quoted! "%{#{key}: {:==, :nil}}"
        is_not_nil_map_entry = Code.string_to_quoted! "%{#{key}: {:!=, :nil}}"
        lt_map_entry = Code.string_to_quoted! "%{#{key}: {:<, _}}"
        lte_map_entry = Code.string_to_quoted! "%{#{key}: {:<=, _}}"
        gt_map_entry = Code.string_to_quoted! "%{#{key}: {:>, _}}"
        gte_map_entry = Code.string_to_quoted! "%{#{key}: {:>=, _}}"
        in_map_entry = Code.string_to_quoted! "%{#{key}: {:in, _}}"

        quote do
          # Keyword queries
          defp build_keyword_query(query, unquote(key), {:in, value}) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :in, unquote(key), ^value)}
          end
          defp build_keyword_query(query, unquote(key), {:>=, value}) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :gte, unquote(key), ^value)}
          end
          defp build_keyword_query(query, unquote(key), {:>, value}) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :gt, unquote(key), ^value)}
          end
          defp build_keyword_query(query, unquote(key), {:<=, value}) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :lte, unquote(key), ^value)}
          end
          defp build_keyword_query(query, unquote(key), {:<, value}) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :lt, unquote(key), ^value)}
          end
          defp build_keyword_query(query, unquote(key), {:!=, nil}) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :not_nil, unquote(key))}
          end
          defp build_keyword_query(query, unquote(key), {:==, nil}) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :is_nil, unquote(key))}
          end
          defp build_keyword_query(query, unquote(key), {:!=, value}) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :not, unquote(key), ^value)}
          end
          defp build_keyword_query(query, unquote(key), {:==, value}) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :eq, unquote(key), ^value)}
          end
          defp build_keyword_query(query, unquote(key), nil) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :is_nil, unquote(key))}
          end
          defp build_keyword_query(query, unquote(key), value) do
            {:ok, EctoSchemaStore.BuildQueries.build_ecto_query(query, :eq, unquote(key), ^value)}
          end

          # Map queries
          defp build_query(query, unquote(is_nil_map_entry) = filters) do
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :is_nil, unquote(key))

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(is_nil_atom_map_entry) = filters) do
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :is_nil, unquote(key))

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(is_not_nil_map_entry) = filters) do
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :not_nil, unquote(key))

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(not_map_entry) = filters) do
            value = elem(filters[unquote(key)], 1)
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :not, unquote(key), ^value)

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(lt_map_entry) = filters) do
            value = elem(filters[unquote(key)], 1)
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :lt, unquote(key), ^value)

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(lte_map_entry) = filters) do
            value = elem(filters[unquote(key)], 1)
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :lte, unquote(key), ^value)

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(gt_map_entry) = filters) do
            value = elem(filters[unquote(key)], 1)
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :gt, unquote(key), ^value)

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(gte_map_entry) = filters) do
            value = elem(filters[unquote(key)], 1)
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :gte, unquote(key), ^value)

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(in_map_entry) = filters) do
            value = elem(filters[unquote(key)], 1)
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :in, unquote(key), ^value)

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(eq_map_entry) = filters) do
            value = elem(filters[unquote(key)], 1)
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :eq, unquote(key), ^value)

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end

          defp build_query(query, unquote(map_entry) = filters) do
            value = filters[unquote(key)]
            query = EctoSchemaStore.BuildQueries.build_ecto_query(query, :eq, unquote(key), ^value)

            build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(unquote(key)))
          end
        end
      end
    
    final_function =
      quote do
        def schema_fields, do: unquote(keys)
        def schema_associations, do: unquote(assocs)

        defp build_keyword_query(query, key, _value) do
          {:error, "Invalid field for #{unquote(schema)} '#{key}'"}
        end
        defp build_query(query, []), do: {:ok, query}
        defp build_query(query, [{key, value} | t]) do
          case build_keyword_query(query, key, value) do
            {:ok, query} -> build_query query, t
            {:error, _message} = error -> error
          end
        end
        defp build_query(query, %{} = filters) do
          if Enum.empty? filters do
            {:ok, query}
          else
            {:error, "Invalid fields for #{unquote(schema)} #{inspect filters}"}
          end
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

    [getters]
    |> Enum.concat(functions)
    |> Enum.concat([final_function])
  end  
end
