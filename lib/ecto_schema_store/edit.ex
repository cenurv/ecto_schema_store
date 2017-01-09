defmodule EctoSchemaStore.Edit do
  @moduledoc false

  defmacro build(schema, repo) do
    keys = EctoSchemaStore.Utils.keys(Macro.expand(schema, __CALLER__), false)

    quote do
      defp default_edit_options do
        [changeset: :changeset]
      end

      defp run_changeset(default_value, params, changeset) when is_atom changeset do
        apply(unquote(schema), changeset, [default_value, params])
      end
      defp run_changeset(default_value, params, changeset) when is_function changeset do
        changeset.(default_value, params)
      end

      @doc """
      Insert a record into `#{unquote(schema)}` via `#{unquote(repo)}`.

      Options:

      * `:changeset`        - By default use :changeset on the schema otherwise use the provided changeset name.
      """
      def insert(params \\ %{}, opts \\ [])
      def insert(%unquote(schema){} = model, _opts) do
        repo = unquote(repo)

        case repo.insert model do
          {:error, _} = error -> error
          {:ok, model} = result ->
            on_after_insert(model)
            {:ok, model}
        end
      end
      def insert(params, opts) when is_list params do
        insert Enum.into(params, %{}), opts
      end
      def insert(params, opts) do
        opts = Keyword.merge default_edit_options(), opts
        changeset = Keyword.get opts, :changeset
        errors_to_map = Keyword.get opts, :errors_to_map, false

        default_value = struct unquote(schema), %{}
        repo = unquote(repo)
        params = alias_filters(params)

        change = 
          if changeset do
            run_changeset default_value, params, changeset
          else
            Ecto.Changeset.change(default_value, params)
          end

        case repo.insert change do
          {:error, changeset} = error ->
            if errors_to_map do
              {:error, EctoSchemaStore.Utils.interpret_errors(changeset, errors_to_map)}
            else
              error
            end
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
          Keyword.merge(default_edit_options(), opts)
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
          Keyword.merge(default_edit_options(), opts)
          |> Keyword.merge([changeset: nil])

        insert! params, opts
      end

      @doc """
      Updates a record in `#{unquote(schema)}` via `#{unquote(repo)}`.

      Options:

      * `:changeset`        - By default use :changeset on the schema otherwise use the provided changeset name.
      """
      def update(id_or_model, params, opts \\ [])
      def update(id_or_model, params, opts) when is_list params do
        update id_or_model, Enum.into(params, %{}), opts
      end
      def update(id_or_model, params, opts) do
        opts = Keyword.merge default_edit_options(), opts
        changeset = Keyword.get opts, :changeset
        errors_to_map = Keyword.get opts, :errors_to_map, false

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
            run_changeset model, params, changeset
          else
            Ecto.Changeset.change(model, params)
          end

        case repo.update change do
          {:error, changeset} = error ->
            if errors_to_map do
              {:error, EctoSchemaStore.Utils.interpret_errors(changeset, errors_to_map)}
            else
              error
            end
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
          Keyword.merge(default_edit_options(), opts)
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
          Keyword.merge(default_edit_options(), opts)
          |> Keyword.merge([changeset: nil])

        update! id_or_model, params, opts
      end

      @doc """
      Queries for the provided query parameters and updates the record if it is
      found. If not the record is created.
      """
      def update_or_create(attributes, query, opts \\ []) do
        case one(query) do
          nil -> insert(attributes, opts)
          record -> update(record, attributes, opts)
        end
      end

      @doc """
      Like `update_or_create` but throws and error instead of returning a tuple.
      """
      def update_or_create!(attributes, query, opts \\ []) do
        case one(query) do
          nil -> insert_fields!(attributes, opts)
          record -> update_fields!(record, attributes, opts)
        end
      end

      @doc """
      Queries for the provided query parameters and updates the record if it is
      found. If not the record is created. Just saves without passing through a
      changeset.
      """
      def update_or_create_fields(attributes, query) do
        case one(query) do
          nil -> insert_fields attributes
          record -> update_fields record, attributes
        end
      end

      @doc """
      Like `update_or_create` but throws and error instead of returning a tuple.
      """
      def update_or_create_fields!(attributes, query) do
        case one(query) do
          nil -> insert_fields! attributes
          record -> update_fields! record, attributes
        end
      end

      @doc """
      ## Experimental ##

      A update statement sent direct to the data store. Uses `Ecto.Repo.update_all`, will
      not update autogenerate field. However, if :updated_at is present, the value will be
      passed a new Ecto.NaiveDateTime value. Changeset will not be applied.
      Use with caution. Query params will be processed like `all` or `one`.
      
      Currently not documented, experimental addition. This may be better set up in the
      individual store using the following code:

      ```elixir
      def update_all(query: query_params, set: params) do
        repo().update_all build_query!(query_params), [set: params]
      end
      ```

      This can then be modified specifically to the use case and not applied to all Repos.
      I may change my mind about this, so I would not reccommend making code dependent upon
      this yet.

      The biggest reasons for the hesitation is that `Ecto.Repo.update_all` basically just
      submits as is to the database and may provide other options that will not be
      supported here as that this is mean't to be a simplistic implementation.
      """
      def update_all(query: query_params, set: params) when is_map params do
        update_all query: query_params, set: Enum.into(params, [])
      end
      def update_all(query: query_params, set: params) do
        keys = unquote(keys)
        params =
          if :updated_at in keys do
            updated_at = Keyword.get params, :updated_at, :undefined

            if updated_at == :undefined do
              Enum.concat params, [updated_at: DateTime.to_naive(DateTime.utc_now)]
            else
              params
            end
          else
            params
          end

        repo().update_all build_query!(query_params), [set: params]
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
