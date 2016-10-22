defmodule EctoStore do

  defmacro __using__(opts) do
    schema = Keyword.get opts, :schema
    repo = Keyword.get opts, :repo

    quote do
      import EctoStore
      require EctoStore.Fetch
      require EctoStore.BuildQueries
      require EctoStore.Edit
      import EctoStore.Alias
      import Ecto.Query
      alias unquote(repo), as: Repo

      def schema, do: unquote(schema)

      EctoStore.Alias.build
      EctoStore.BuildQueries.build(unquote(schema))
      EctoStore.Fetch.build(unquote(repo))
      EctoStore.Edit.build(unquote(schema), unquote(repo))
    end
  end

end
