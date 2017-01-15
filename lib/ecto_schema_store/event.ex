defmodule EctoSchemaStore.Event do
  @moduledoc false

  defmacro build do
    all_events = [:after_insert, :after_update, :after_delete, :before_insert, :before_update, :before_delete]

    for event <- all_events do
      name = String.to_atom "on_#{event}"
      has_name = String.to_atom "has_#{event}?"

      override =
        []
        |> Keyword.put(name, 1)
        |> Keyword.put(has_name, 0)

      quote do
        def unquote(has_name)(), do: false
        def unquote(name)(_), do: nil

        defoverridable unquote(override)
      end
    end
  end

  defmacro create_queue do
    if Code.ensure_compiled?(EventQueues) do
      quote do
        defmodule Queue do
          use EventQueues, type: :queue
        end
      end
    else
      throw "EventQueues must be included in your application to use Schema Store Events"
    end
  end

  defmacro announces(events: events) do
    quote do
      announces events: unquote(events), queues: [__MODULE__.Queue]
    end
  end

  defmacro announces(events: events, queues: queues) when not is_list(events) do
    quote do
      announces events: [unquote(events)], queues: unquote(queues)
    end
  end
  defmacro announces(events: events, queues: queues) when not is_list(queues) do
    quote do
      announces events: unquote(events), queues: [unquote(queues)]
    end
  end
  defmacro announces(events: events, queues: queues) do
    if Code.ensure_compiled?(EventQueues) do
      for event <- events do
        name = String.to_atom "on_#{event}"
        has_name = String.to_atom "has_#{event}?"

        for queue <- queues do
          quote do
            def unquote(has_name)(), do: true
            def unquote(name)(event), do: unquote(queue).announce event
          end
        end
      end
    else
      throw "EventQueues must be included in your application to use Schema Store Events"
    end
  end
  defmacro announces(anything) do
    IO.inspect anything
    []
  end


  # defmacro on(events, matching, do: block) when is_list events do
  #   for event <- events do
  #     name = String.to_atom "on_#{event}"

  #     quote do
  #       defp unquote(name)(unquote(matching)) do
  #         unquote(block)
  #       end
  #     end
  #   end
  # end
  # defmacro on(event, matching, do: block) when is_atom event do
  #   quote do
  #     on([unquote(event)], unquote(matching)) do
  #       unquote(block)
  #     end
  #   end
  # end
end
