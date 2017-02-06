defmodule EctoSchemaStore.Event do
  @moduledoc false

  alias EventQueues.Event

  def new(fields) do
    previous_model = Keyword.get fields, :previous_model, nil
    new_model = Keyword.get fields, :new_model, nil
    changeset = Keyword.get fields, :changeset, nil
    current_action = Keyword.get fields, :current_action, nil
    store = Keyword.get fields, :store, nil
    options = Keyword.get fields, :options, []
    params = Keyword.get fields, :params, nil

    Event.new category: store.schema(),
              name: current_action,
              data: %{
                previous: previous_model,
                current: new_model,
                changeset: changeset,
                originator: store,
                options: options,
                params: params
              }
  end
end
