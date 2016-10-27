defmodule EctoSchemaStore.Edit do
  @moduledoc false

  defmacro build(schema, repo) do
    quote do
      defp default_edit_options do
        [changeset: :changeset]
      end

      @doc """
      Insert a record into `#{unquote(schema)}` via `#{unquote(repo)}`.

      Options:

      * `:changeset`        - By default use :changeset on the schema otherwise use the provided changeset name.
      """
      def insert(params, opts \\ []) do
        opts = Keyword.merge default_edit_options, opts
        changeset = Keyword.get opts, :changeset

        default_value = struct unquote(schema), %{}
        repo = unquote(repo)
        params = alias_filters(params)

        change = 
          if changeset do
            apply(unquote(schema), changeset, [default_value, params])
          else
            Ecto.Changeset.change(default_value, params)
          end

        case repo.insert change do
          {:error, _} = error -> error
          {:ok, model} = result ->
            on_after_insert(model)
            {:ok, model}
        end
      end

      @doc """
      Insert a record into `#{unquote(schema)}` via `#{unquote(repo)}`. Sets the change directly and does not use a changeset.
      """
      def insert_fields(params, opts \\ []) do
        opts =
          Keyword.merge(default_edit_options, opts)
          |> Keyword.merge([changeset: nil])

        insert params, opts
      end

      @doc """
      Like `insert` but throws and error instead of returning a tuple.
      """
      def insert!(params, opts \\ []) do
        case insert params, opts do
          {:error, reason} -> throw reason
          {:ok, result} -> result
        end
      end

      @doc """
      Like `insert_fields` but throws and error instead of returning a tuple.
      """
      def insert_fields!(params, opts \\ []) do
        opts =
          Keyword.merge(default_edit_options, opts)
          |> Keyword.merge([changeset: nil])

        insert! params, opts
      end

      @doc """
      Updates a record in `#{unquote(schema)}` via `#{unquote(repo)}`.

      Options:

      * `:changeset`        - By default use :changeset on the schema otherwise use the provided changeset name.
      """
      def update(id_or_model, params, opts \\ []) do
        opts = Keyword.merge default_edit_options, opts
        changeset = Keyword.get opts, :changeset

        repo = unquote(repo)
        params = alias_filters(params)

        model =
          if is_integer id_or_model do
            struct unquote(schema), %{id: id_or_model}
          else
            id_or_model
          end

        change = 
          if changeset do
            apply(unquote(schema), changeset, [model, params])
          else
            Ecto.Changeset.change(model, params)
          end

        case repo.update change do
          {:error, _} = error -> error
          {:ok, model} = result ->
            on_after_update(model)
            {:ok, model}
        end
      end

      @doc """
      Updates a record in `#{unquote(schema)}` via `#{unquote(repo)}`. Sets the change directly and does not use a changeset.
      """
      def update_fields(id_or_model, params, opts \\ []) do
        opts =
          Keyword.merge(default_edit_options, opts)
          |> Keyword.merge([changeset: nil])

        update id_or_model, params, opts
      end

      @doc """
      Like `update` but throws and error instead of returning a tuple.
      """
      def update!(id_or_model, params, opts \\ []) do
        case update id_or_model, params, opts do
          {:error, reason} -> throw reason
          {:ok, result} -> result
        end
      end

      @doc """
      Like `update_fields` but throws and error instead of returning a tuple.
      """
      def update_fields!(id_or_model, params, opts \\ []) do
        opts =
          Keyword.merge(default_edit_options, opts)
          |> Keyword.merge([changeset: nil])

        update! id_or_model, params, opts
      end

      @doc """
      Deletes a record in `#{unquote(schema)}` via `#{unquote(repo)}`.
      """
      def delete(id_or_model) do
        repo = unquote(repo)
  
        model =
          if is_integer id_or_model do
            struct unquote(schema), %{id: id_or_model}
          else
            id_or_model
          end

        case repo.delete model do
          {:error, _} = error -> error
          {:ok, model} = result ->
            on_after_delete(model)
            {:ok, model}
        end
      end

      @doc """
      Like `delete` but throws and error instead of returning a tuple.
      """
      def delete!(model_or_id) do
        case delete model_or_id do
          {:error, reason} -> throw reason
          {:ok, result} -> result
        end
      end
    end
  end
end
