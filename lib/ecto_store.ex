defmodule EctoStore do

  defmacro __using__(opts) do
    schema = Keyword.get opts, :schema

    quote do
      import EctoStore
      require EctoStore.BuildParams
      import Ecto.Query, only: [from: 2]

      EctoStore.BuildParams.build(unquote(schema))
    end
  end

end
