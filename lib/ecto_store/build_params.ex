defmodule EctoStore.BuildParams do
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
        param = Keyword.put([], key, {:value, [], EctoStore.BuildParams})
        query = [{:q, [], EctoStore.BuildParams}, key]

        {:defp, [context: EctoStore.BuildParams, import: Kernel],
        [{:build_query, [context: EctoStore.BuildParams],
          [{:query, [], EctoStore.BuildParams},
            {:=, [],
            [{:%{}, [], param},
              {:filters, [], EctoStore.BuildParams}]}]},                                                                                                                                                
          [do: {:__block__, [],                                                                                                                                                                         
            [{:=, [],                                                                                                                                                                                   
              [{:query, [], EctoStore.BuildParams},                                                                                                                                                     
              {:from, [],                                                                                                                                                                              
                [{:in, [context: EctoStore.BuildParams, import: Kernel],                                                                                                                                
                  [{:q, [], EctoStore.BuildParams}, 
                   {:query, [], EctoStore.BuildParams}]},                                                                                                                             
                [where: {:==, [context: EctoStore.BuildParams, import: Kernel],                                                                                                                        
                  [{{:., [], query}, [], []},                                                                                                                        
                    {:^, [], [{:value, [], EctoStore.BuildParams}]}]}]]}]},                                                                                                                             
            {:build_query, [],                                                                                                                                                                         
              [{:query, [], EctoStore.BuildParams},                                                                                                                                                     
              {:|>, [context: EctoStore.BuildParams, import: Kernel],                                                                                                                                  
                [{:filters, [], EctoStore.BuildParams},                                                                                                                                                 
                {{:., [],                                                                                                                                                                              
                  [{:__aliases__, [alias: false], [:EctoStore, :Utils]},                                                                                                                               
                    :remove_from_map]}, [], [key]}]}]}]}]]}

      end
    
    final_function =
      quote do
        defp build_query(query, %{} = filters) do
          if Enum.empty? filters do
            query
          else
            {:error, "Invalid fields for #{unquote(schema)} #{inspect filters}"}
          end
        end

        def build_query(filters) do
          build_query unquote(schema), filters
        end
      end

    Enum.concat functions, [final_function]
  end
end
