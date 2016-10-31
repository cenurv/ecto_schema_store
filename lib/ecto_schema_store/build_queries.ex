defmodule EctoSchemaStore.BuildQueries do
  @moduledoc false

  defmacro build(schema) do
    keys = EctoSchemaStore.Utils.keys(Macro.expand(schema, __CALLER__))

    # Save to generate AST in the future.
    # IO.inspect(
    #   quote do
    #     defp build_query(query, %{key: value} = filters) do
    #       query = from q in query,
    #               where: q.key == ^value

    #       build_query(query, filters |> EctoSchemaStore.Utils.remove_from_map(:key))
    #     end
    #   end
    # )

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
        param = Keyword.put([], key, {:value, [], EctoSchemaStore})
        query = [{:q, [], EctoSchemaStore}, key]

        {:defp, [context: EctoSchemaStore, import: Kernel],
        [{:build_query, [context: EctoSchemaStore],
          [{:query, [], EctoSchemaStore},
            {:=, [],
            [{:%{}, [], param},
              {:filters, [], EctoSchemaStore}]}]},                                                                                                                                                
          [do: {:__block__, [],                                                                                                                                                                         
            [{:=, [],                                                                                                                                                                                   
              [{:query, [], EctoSchemaStore},                                                                                                                                                     
              {:from, [],                                                                                                                                                                              
                [{:in, [context: EctoSchemaStore, import: Kernel],                                                                                                                                
                  [{:q, [], EctoSchemaStore}, 
                   {:query, [], EctoSchemaStore}]},                                                                                                                             
                [where: {:==, [context: EctoSchemaStore, import: Kernel],                                                                                                                        
                  [{{:., [], query}, [], []},                                                                                                                        
                    {:^, [], [{:value, [], EctoSchemaStore}]}]}]]}]},                                                                                                                             
            {:build_query, [],                                                                                                                                                                         
              [{:query, [], EctoSchemaStore},                                                                                                                                                     
              {:|>, [context: EctoSchemaStore, import: Kernel],                                                                                                                                  
                [{:filters, [], EctoSchemaStore},                                                                                                                                                 
                {{:., [],                                                                                                                                                                              
                  [{:__aliases__, [alias: false], [:EctoSchemaStore, :Utils]},                                                                                                                               
                    :remove_from_map]}, [], [key]}]}]}]}]]}

      end
    
    final_function =
      quote do
        defp build_query(query, %{} = filters) do
          if Enum.empty? filters do
            {:ok, query}
          else
            {:error, "Invalid fields for #{unquote(schema)} #{inspect filters}"}
          end
        end

        @doc """
        Build an `Ecto.Query` from the provided fields and values map.

        Available fields: `#{inspect unquote(keys)}`
        """
        def build_query(filters \\ %{})
        def build_query(filters) when is_list filters do
          build_query Enum.into(filters, %{})
        end
        def build_query(filters) do
          build_query unquote(schema), alias_filters(filters)
        end

        @doc """
        Build an `Ecto.Query` from the provided fields and values map. Returns the values or throws an error.

        Available fields: `#{inspect unquote(keys)}`
        """
        def build_query!(filters \\ %{})
        def build_query!(filters) when is_list filters do
          build_query! Enum.into(filters, %{})
        end
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
