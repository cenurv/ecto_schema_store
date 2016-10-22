defmodule EctoStore do

  defmacro __using__(opts) do
    schema = Keyword.get opts, :schema
    repo = Keyword.get opts, :repo

    quote do
      import EctoStore
      require EctoStore.Fetch
      require EctoStore.BuildQueries
      import Ecto.Query
      alias unquote(repo), as: Repo

      EctoStore.BuildQueries.build(unquote(schema))
      EctoStore.Fetch.build(unquote(repo))
    end
  end

end
