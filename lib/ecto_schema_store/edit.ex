defmodule EctoSchemaStore.Edit do
  defmacro build(schema, repo) do
    quote do
      def insert(params, changeset \\ :changeset) do
        default_value = struct unquote(schema), %{}
        repo = unquote(repo)
        params = alias_filters(params)

        change = apply(unquote(schema), changeset, [default_value, params])
        repo.insert change
      end

      def insert!(params, changeset \\ :changeset) do
        case insert params, changeset do
          {:error, reason} -> throw reason
          {:ok, result} -> result
        end
      end

      def update(id_or_model, params, changeset \\ :changeset)
      def update(id, params, changeset) when is_integer id do
        repo = unquote(repo)
        default_value = struct unquote(schema), %{id: id}
        params = alias_filters(params)
        change = apply(unquote(schema), changeset, [default_value, params])
        repo.update change
      end
      def update(model, params, changeset) do
        repo = unquote(repo)
        params = alias_filters(params)

        change = apply(unquote(schema), changeset, [model, params])
        repo.update change
      end

      def update!(id_or_model, params, changeset \\ :changeset)
      def update!(id, params, changeset) when is_integer id do
        case update id, params, changeset do
          {:error, reason} -> throw reason
          {:ok, result} -> result
        end
      end
      def update!(model, params, changeset) do
        case update model, params, changeset do
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
