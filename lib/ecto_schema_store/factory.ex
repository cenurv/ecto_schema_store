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

  defmacro faker(mapping, opts \\ []) when is_list(mapping) do
    if not Code.ensure_loaded?(Faker) do
      throw "Faker module not loaded. Please include {:faker, \"~> 0.10.0\"} in your mix.exs file."
    end

    quote do
      @doc """
      The Faker module mapping for schema keys.
      """
      def faker_mapping, do: Enum.into(unquote(mapping), %{})

      def fake, do: fake(schema().__schema__(:fields))
      def fake(allowed_keys) do
        mapping = faker_mapping()
        params =
          for key <- Map.keys(mapping) do
            if key in allowed_keys do
              if is_function(mapping[key]) do
                mapping[key].()
              else
                {module, function} = mapping[key]
                module = Module.concat(Faker, module)
                {key, apply(module, function, [])}
              end
            else
              nil
            end
          end

        Enum.reject(params, &(is_nil(&1)))
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
