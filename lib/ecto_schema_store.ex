defmodule EctoSchemaStore do

  defmacro __using__(opts) do
    schema = Keyword.get opts, :schema
    repo = Keyword.get opts, :repo

    quote do
      import EctoSchemaStore
      require EctoSchemaStore.Fetch
      require EctoSchemaStore.BuildQueries
      require EctoSchemaStore.Edit
      import EctoSchemaStore.Alias
      import Ecto.Query, except: [update: 3]
      alias unquote(repo), as: Repo

      def schema, do: unquote(schema)
      def repo, do: unquote(repo)

      EctoSchemaStore.Alias.build
      EctoSchemaStore.BuildQueries.build(unquote(schema))
      EctoSchemaStore.Fetch.build(unquote(repo))
      EctoSchemaStore.Edit.build(unquote(schema), unquote(repo))
    end
  end

end
