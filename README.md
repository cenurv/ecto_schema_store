# Ecto Schema Store

This library is used to create customizable data stores for individual ecto schemas.

With the following schema:

```elixir
defmodule Person do
  use EctoTest.Web, :model

  schema "people" do
    field :name, :string
    field :email, :string

    timestamps
  end

  def changeset(model, params) do
    model
    |> cast(params, [:name, :email])
  end
end
```

You can create a store with the following:

```elixir
defmodule PersonStore do
  use EctoSchemaStore, schema: Person, repo: MyApp.Repo
end
```

## Querying ##

The following functions are provided in a store for retrieving data.

* `all`         - Fetch all records
* `one`         - Return a single record

Sample Queries:

```elixir
# Get all records in a table.
PersonStore.all

# Get all records fields that match the provided value.
PersonStore.all %{name: "Bob"}
PersonStore.all %{name: "Bob", email: "bob@nowhere.test"}

# Return a single record.
PersonStore.one %{name: "Bob"}

# Return a specific record by id.
PersonStore.one 12
```

## Editing ##

The following functions are provided in a store for editing data.

* `insert`              - Insert a record based upon supplied parameters map.
* `trusted_insert`      - Insert the record without using a changeset. Intended only for trusted controlled data.
* `insert!`             - Same as `insert` but throws an error instead of returning a tuple.
* `trusted_insert!`     - Insert the record without using a changeset. Intended only for trusted controlled data.
* `update`              - Update a record based upon supplied parameters map.
* `trusted_update`      - Update the record without using a changeset. Intended only for trusted controlled data.
* `update!`             - Same as `update` but throws an error instead of returning a tuple.
* `trusted_update!`     - Update the record without using a changeset. Intended only for trusted controlled data.
* `delete`              - Delete a record.
* `delete!`             - Same as `delete` but throws an error instead of returning a tuple.

Sample Usage:

```elixir
bob = PersonStore.insert! %{name: "Bob", email: "bob@nowhere.test"}
bob = PersonStore.update! bob, %{email: "bob2@nowhere.test"}
PersonStore.delete bob

# Updates/deletes can also occur by id.
PersonStore.update! 12, %{email: "bob2@nowhere.test"}
PersonStore.delete 12
```

## Changesets ##

The `insert` and `update` functions by default use a changeset on the provided schema name `:changeset` for inserting and updating.
This can be overridden and a specific changeset name provided.

```elixir
bob = PersonStore.insert! %{name: "Bob", email: "bob@nowhere.test"}, changeset: :insert_changeset
bob = PersonStore.update! bob, %{email: "bob2@nowhere.test"}, changeset: :update_changeset
bob = PersonStore.update! bob, %{email: "bob2@nowhere.test"}, changeset: :my_other_custom_changeset
``` 

## References ##

The internal references to the schema and the provided Ecto Repo are provided as convience functions.

* `schema`         - returns the schema reference used internally by the store.
* `repo`           - returns the Ecto Repo reference used internally by the store.

## Custom Actions ##

Since a store is just an ordinary module, you can add your actions and build off private APIs to the store. For convience
`Ecto.Query` is already fully imported into the module.

A store is provided the following custom internal API:

* `build_query`       - Builds a `Ecto.Query` struct based upon the map params input.

```elixir
defmodule PersonStore do
  use EctoSchemaStore, schema: Person, repo: MyApp.Repo

  def get_all_ordered_by_name do
    build_query
    |> order_by([:name])
    |> all
  end

  def find_by_email(email) do
    %{email: email}
    |> build_query
    |> order_by([:name])
    |> all
  end

  def get_all_ordered_by_name_using_ecto_directly do
    query = from p in schema,
            order_by: [p.name]
    
    repo.all query
  end
end
```

## Schema Field Aliases ##

Sometimes field names get changed or the developer wishes to have an alias that represents another field.
These work for both querying and editing schema models.

```elixir
defmodule PersonStore do
  use EctoSchemaStore, schema: Person, repo: MyApp.Repo

  alias_fields email_address: :email
end

PersonStore.all %{email_address: "bob@nowhere.test"}
PersonStore.update! 12, %{email_address: "bob@nowhere.test"}
```

## Filter or Params Map ##

Many of the API calls used by a store take a map of fields as input. Normal Ecto
requires param maps to be either all atom or string keyed but not mixed. A schema
store will convert every map provided into atom keys before aliasing and passing
on to Ecto. This means you can provide a mixture of both. This will allow a
developer to combine multiple maps together and not worry about what kind of
keys were used.

However, if you provide the same value twice as both an atom and string key then
only one will be used.

```elixir
PersonStore.insert! %{"name" => "Bob", email: "bob2@nowhere.test"}
```