defmodule EctoSchemaStore.Event do
  @moduledoc false

  defmacro build do
    all_events = [:after_insert, :after_update, :after_delete]

    for event <- all_events do
      name = String.to_atom "on_#{event}"
      override = Keyword.put [], name, 1

      quote do
        defp unquote(name)(_), do: nil

        defoverridable unquote(override)
      end
    end
  end

  defmacro on(events, matching, do: block) when is_list events do
    for event <- events do
      name = String.to_atom "on_#{event}"

      quote do
        defp unquote(name)(unquote(matching)) do
          unquote(block)
        end
      end
    end
  end
  defmacro on(event, matching, do: block) when is_atom event do
    quote do
      on([unquote(event)], unquote(matching)) do
        unquote(block)
      end
    end
  end
end
