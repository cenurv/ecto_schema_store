# REST API Builder Provider

Ecto Schema Store now implements an API resource provider for the `rest_api_builder` project. This provider allows a
developer to back a rest service using a store provided by this library.

This works is still early access may be changed significantly as that the `rest_api_builder` library is still under
initial development.

This documentation will focus on the provider itself. To see more documentation for `rest_api_builder` please visit that
project in Hex.

# Set Up

```elixir
defmodule Customer do
  use EctoTest.Web, :model

  schema "customers" do
    field :name, :string
    field :email, :string
    field :account_closed, :boolean, default: false

    timestamps
  end

  def changeset(model, params) do
    model
    |> cast(params, [:name, :email])
  end
end

defmodule CustomerStore do
  use EctoSchemaStore, schema: Customer, repo: MyApp.Repo
end

defmodule CustomersApi do
  use RestApiBuilder, plural_name: :customers, singular_name: :customer, activate: :all

  provider EctoSchemaStore.ApiProvider, store: CustomerStore
end

```

# Configuring the provider

* `store`                    - The module that implements the store interface.
* `parent_field`             - The field name of the parent schema id in the Ecto schema definition. This is used when a REST API module is a child to another.
* `soft_delete`              - By default the provider will delete the record. This takes a tuple of `{field_name, value_to_set}`.
                               When set, will update the record and exclude it from future query results.
* `include`                  - Which fields to include in the resource. By default only, non-association fields are included.
* `exclude`                  - Which fields that woudl normally be included need to be excluded from the resource output.
* `preload`                  - List of associations to preload when querying records. Dependent on need, child associations may be better as their own REST API module.

In addition, the provider also adds a command to the REST API module that allows the developer to set which changesets to use when creating or updating by default.

```elixir
defmodule CustomersApi do
  use RestApiBuilder, plural_name: :customers, singular_name: :customer, activate: :all

  provider EctoSchemaStore.ApiProvider, store: CustomerStore,
                                        soft_delete: {:account_closed, true},
                                        exclude: [:account_closed]

  changeset :create_changeset, :create
  changeset :update_changeset, :update
end
```

By default, the standard name of :changset is used like normal within the store itself. To use no changeset, just provide the following:

```elixir
defmodule CustomersApi do
  use RestApiBuilder, plural_name: :customers, singular_name: :customer, activate: :all

  provider EctoSchemaStore.ApiProvider, store: CustomerStore,
                                        soft_delete: {:account_closed, true},
                                        exclude: [:account_closed]

  changeset nil
end
```

You can also provide a default changeset for both create and update:

```elixir
defmodule CustomersApi do
  use RestApiBuilder, plural_name: :customers, singular_name: :customer, activate: :all

  provider EctoSchemaStore.ApiProvider, store: CustomerStore,
                                        soft_delete: {:account_closed, true},
                                        exclude: [:account_closed]

  changeset :api_changeset
end
```

The changeset could also be changed progarmatically such as with an plug to be set based upon the using accessing the service.
This is done by adding a :changeset value to the `Plug.Conn` assigns map.

```elixir
defmodule CustomersApi do
  use RestApiBuilder, plural_name: :customers, singular_name: :customer, activate: :all, default_plugs: false
  import Plug.Conn

  provider EctoSchemaStore.ApiProvider, store: CustomerStore,
                                        soft_delete: {:account_closed, true},
                                        exclude: [:account_closed]

  plugs do
    plug :check_access_level
  end

  def check_access_level(%Plug.Conn{assigns: %{current_user: %{type: "admin"}}} = conn, _opts) do
    assign conn, :changeset, :admin_changeset
  end
  def check_access_level(conn, _opts), do: conn

  changeset :standard_user_changeset
end
```