defmodule EctoSchemaStore do

  @moduledoc """
  This library is used to create customizable data stores for individual ecto schemas.

  See README.md for usage documentation.
  """

  defmacro __using__(opts) do
    schema = Keyword.get opts, :schema
    repo = Keyword.get opts, :repo

    quote do
      import EctoSchemaStore
      require Logger
      require EctoSchemaStore.Fetch
      require EctoSchemaStore.BuildQueries
      require EctoSchemaStore.Edit
      require EctoSchemaStore.Factory
      import EctoSchemaStore.Alias
      import Ecto.Changeset
      import Ecto.Query, except: [update: 3, update: 2]
      import EctoSchemaStore.Factory
      import EctoSchemaStore.Assistant
      alias unquote(repo), as: Repo
      alias Ecto.Query

      use EventQueues, type: :announcer
      require EventQueues

      EventQueues.defevents [:after_insert, :after_update, :after_delete, :before_insert, :before_update, :before_delete]

      @doc """
      Returns a reference to the schema module `#{unquote(schema)}`.
      """
      def schema, do: unquote(schema)
      @doc """
      Returns a reference to the Ecto Repo module `#{unquote(repo)}`.
      """
      def repo, do: unquote(repo)

      EctoSchemaStore.Alias.build
      EctoSchemaStore.BuildQueries.build(unquote(schema))
      EctoSchemaStore.Fetch.build(unquote(schema), unquote(repo))
      EctoSchemaStore.Edit.build(unquote(schema), unquote(repo))
      EctoSchemaStore.Factory.build
    end
  end

  @doc """
  Wraps standard Ecto Repo transaction with a catch for errors throw from a store
  in order to handle the throwing of errors not from DBConnection more gracefully.
  """
  def transaction(repo, fun) do
    repo.transaction fun
  catch
    %Ecto.Changeset{} = error -> {:error, error}
    %{} = error -> {:error, error}
  end
end
