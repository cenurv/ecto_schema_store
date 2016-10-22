defmodule EctoStore.BuildQueries do
  defmacro build(schema) do
    schema = Macro.expand(schema, __CALLER__)
    impl = struct schema
    keys = Map.keys impl

    ignore = [:__struct__, :__meta__]

    keys = Enum.filter keys, &((&1 in ignore) == false)

    # Save to generate AST in the future.
    # IO.inspect(
    #   quote do
    #     defp build_query(query, %{key: value} = filters) do
    #       query = from q in query,
    #               where: q.key == ^value

    #       build_query(query, filters |> EctoStore.Utils.remove_from_map(:key))
    #     end
    #   end
    # )

    functions =
      for key <- keys do
        param = Keyword.put([], key, {:value, [], EctoStore})
        query = [{:q, [], EctoStore}, key]

        {:defp, [context: EctoStore, import: Kernel],
        [{:build_query, [context: EctoStore],
          [{:query, [], EctoStore},
            {:=, [],
            [{:%{}, [], param},
              {:filters, [], EctoStore}]}]},                                                                                                                                                
          [do: {:__block__, [],                                                                                                                                                                         
            [{:=, [],                                                                                                                                                                                   
              [{:query, [], EctoStore},                                                                                                                                                     
              {:from, [],                                                                                                                                                                              
                [{:in, [context: EctoStore, import: Kernel],                                                                                                                                
                  [{:q, [], EctoStore}, 
                   {:query, [], EctoStore}]},                                                                                                                             
                [where: {:==, [context: EctoStore, import: Kernel],                                                                                                                        
                  [{{:., [], query}, [], []},                                                                                                                        
                    {:^, [], [{:value, [], EctoStore}]}]}]]}]},                                                                                                                             
            {:build_query, [],                                                                                                                                                                         
              [{:query, [], EctoStore},                                                                                                                                                     
              {:|>, [context: EctoStore, import: Kernel],                                                                                                                                  
                [{:filters, [], EctoStore},                                                                                                                                                 
                {{:., [],                                                                                                                                                                              
                  [{:__aliases__, [alias: false], [:EctoStore, :Utils]},                                                                                                                               
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
          build_query unquote(schema), filters
        end

        def build_query!(filters \\ %{}) do
          case build_query(unquote(schema), filters) do
            {:error, reason} -> throw reason
            {:ok, query} -> query
          end
        end
      end

    Enum.concat functions, [final_function]
  end  
end 