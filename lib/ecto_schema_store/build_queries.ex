defmodule EctoSchemaStore.BuildQueries do
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

        def build_query(filters \\ %{}) do
          build_query unquote(schema), alias_filters(filters)
        end

        def build_query!(filters \\ %{}) do
          case build_query(filters) do
            {:error, reason} -> throw reason
            {:ok, query} -> query
          end
        end
      end

    Enum.concat functions, [final_function]
  end  
end 