defmodule EctoSchemaStore.Factory do
  @moduledoc false

  defmacro build do
    quote do
      def generate(keys \\ []) do
        generate keys, %{}
      end
      def generate(keys, fields ) when is_atom keys do
        generate [keys], fields
      end
      def generate(keys, fields) when is_list keys do
        # Default always applies first.
        keys = [:default | keys]
        params_list =
          Enum.map keys, fn(key) ->
            try do
              generate_prepare_fields apply(__MODULE__, :generate_params, [key])
            rescue
              _ ->
                if key != :default do
                  Logger.warn "Factory '#{key}' not found in '#{__MODULE__}'."
                end

                %{}
            end
          end

        params =
          Enum.reduce params_list, %{}, fn(params, acc) ->
            Map.merge acc, params
          end

        fields = generate_prepare_fields fields
        params = Map.merge params, fields

        insert_fields params
      end

      def generate_default(fields \\ %{}) do
        generate [], fields
      end

      def generate_default!(fields \\ %{}) do
        generate! [], fields
      end

      def generate!(keys \\ []) do
        generate! keys, %{}
      end

      def generate!(keys, fields) do
        case generate(keys, fields) do
          {:ok, response} -> response
          {:error, message} -> throw message
        end
      end

      defp generate_prepare_fields(fields) when is_list fields do
        generate_prepare_fields Enum.into(fields, %{})
      end
      defp generate_prepare_fields(fields) when is_map fields do
        alias_filters(fields)
      end
    end
  end

  defmacro factory(function, do: block) do
    name = elem(function, 0)

    quote do
      def generate_params(unquote(name)) do
        unquote(block)
      end
    end
  end

  defmacro factory(do: block) do
    quote do
      factory default do
        unquote block
      end
    end
  end
end
