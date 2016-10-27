defmodule EctoSchemaStore.Edit do
  @moduledoc false

  defmacro build(schema, repo) do
    quote do
      defp default_edit_options do
        [changeset: :changeset]
      end

      def insert(params, opts \\ []) do
        opts = Keyword.merge default_edit_options, opts
        changeset = Keyword.get opts, :changeset

        default_value = struct unquote(schema), %{}
        repo = unquote(repo)
        params = alias_filters(params)

        change = apply(unquote(schema), changeset, [default_value, params])
        repo.insert change
      end

      def insert!(params, opts \\ []) do
        case insert params, opts do
          {:error, reason} -> throw reason
          {:ok, result} -> result
        end
      end

      def update(id_or_model, params, opts \\ [])
      def update(id, params, opts) when is_integer id do
        opts = Keyword.merge default_edit_options, opts
        changeset = Keyword.get opts, :changeset

        repo = unquote(repo)
        default_value = struct unquote(schema), %{id: id}
        params = alias_filters(params)
        change = apply(unquote(schema), changeset, [default_value, params])
        repo.update change
      end
      def update(model, params, opts) do
        opts = Keyword.merge default_edit_options, opts
        changeset = Keyword.get opts, :changeset

        repo = unquote(repo)
        params = alias_filters(params)

        change = apply(unquote(schema), changeset, [model, params])
        repo.update change
      end

      def update!(id_or_model, params, opts \\ [])
      def update!(id, params, opts) when is_integer id do
        case update id, params, opts do
          {:error, reason} -> throw reason
          {:ok, result} -> result
        end
      end
      def update!(model, params, opts) do
        case update model, params, opts do
          {:error, reason} -> throw reason
          {:ok, result} -> result
        end
      end

      def delete(id) when is_integer id do
        repo = unquote(repo)
        default_value = struct unquote(schema), %{id: id}

        repo.delete default_value
      end
      def delete(model) do
        repo = unquote(repo)
        repo.delete model
      end

      def delete!(model_or_id) do
        case delete model_or_id do
          {:error, reason} -> throw reason
          {:ok, result} -> result
        end
      end
    end
  end
end
