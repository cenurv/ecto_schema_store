defmodule EctoSchemaStore do

  @moduledoc """
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

  * `all`                 - Fetch all records
  * `one`                 - Return a single record
  * `refresh`             - Reloads an existing record from the database.
  * `preload_assocs`      - Preload record associations. Same as `Repo.preload`. Providing `:all` will cause all associations to be preloaded.
  * `count_records`       - Count the number of records returned by the provided filters.
  * `exists?`             - Returns true if any records exists for the provided filters.
  * `destructure`         - Return the model as generic Elixir maps without the Ecto content

  Sample Queries:

  ```elixir
  # Get all records in a table.
  PersonStore.all

  # Get all records fields that match the provided value.
  PersonStore.all %{name: "Bob"}
  PersonStore.all %{name: "Bob", email: "bob@nowhere.test"}
  PersonStore.all name: "Bob", email: "bob@nowhere.test"

  # Return a single record.
  PersonStore.one %{name: "Bob"}
  PersonStore.one name: "Bob"

  # Return a specific record by id.
  PersonStore.one 12

  # Refresh
  record = PersonStore.one 12
  record = PersonStore.refresh record

  # Preload after query
  PersonStore.preload_assocs record, :field_name
  PersonStore.preload_assocs record, :all
  PersonStore.preload_assocs record, [:field_name_1, :field_name_2]

  # Destructure
  record = Person.destructure Person.one 12
  ```

  Options:

  * preload            - An atom or list of atoms with the model association keys to preload. Providing `:all` will cause all associations to be preloaded.
  * destructure        - Return the models as generic Elixir maps without the Ecto content. Defaults: `false` 

  ```elixir
  # Get all records in a table.
  PersonStore.all %{}, preload: :field_name

  # Get all records fields that match the provided value.
  PersonStore.all %{name: "Bob"}, preload: [:field_name_1, :field_name_2]

  # Return a single record.
  PersonStore.one %{name: "Bob"}, preload: :all

  # Return a specific record by id.
  PersonStore.one 12, preload: :all, destructure: true
  ```

  ## Filter Operators ##

  Stores support a special syntax for changing the comparison operator in the passed filter map or keyword list.

  Operators:

  * `{:==, value}`            - The field equals this value. This is the default operator when the value is not `nil`.
  * `{:!=, value}`            - The field does not equal the value.
  * `{:==, nil}`              - The field is `nil` or `null` in the database. This is the default operator when the value is `nil`.
  * `{:!=, nil}`              - The field is not `nil` or `null` in the database.
  * `{:<, value}`             - The field is less than the value.
  * `{:<=, value}`            - The field is less than or equal the value.
  * `{:>, value}`             - The field is greater than the value.
  * `{:>=, value}`            - The field is greater than or equal the value.
  * `{:in, []}`               - the field is in the list of provided values.

  ```elixir
  PersonStore.all %{name: nil}
  PersonStore.all %{name: {:==, nil}}
  PersonStore.all name: {:!=, nil}
  PersonStore.all name: {:!=, "Bob"}
  PersonStore.all name: {:in, ["Bob"]}, email: "bob@nowhere.test"
  ```

  ## Editing ##

  The following functions are provided in a store for editing data.

  * `insert`                       - Insert a record based upon supplied parameters map.
  * `insert_fields`                - Insert the record without using a changeset.
  * `insert!`                      - Same as `insert` but throws an error instead of returning a tuple.
  * `insert_fields!`               - Same as `insert_fields` but throws an error instead of returning a tuple.
  * `update`                       - Update a record based upon supplied parameters map.
  * `update_fields`                - Update the record without using a changeset.
  * `update!`                      - Same as `update` but throws an error instead of returning a tuple.
  * `update_fields!`               - Same as `update_fields` but throws an error instead of returning a tuple.
  * `update_or_create`             - Updates a record if the provided query values are found. Otherwise creates the record.
  * `update_or_create!`            - Same as `update_or_create` but throws an error instead of returning a tuple.
  * `update_or_create_fields`      - Updates a record if the provided query values are found. Otherwise creates the record. Does not use a changeset.
  * `update_or_create_fields!`     - Same as `update_or_create_fields` but throws an error instead of returning a tuple.
  * `delete`                       - Delete a record.
  * `delete!`                      - Same as `delete` but throws an error instead of returning a tuple.

  Sample Usage:

  ```elixir
  # Using Map
  bob = PersonStore.insert! %{name: "Bob", email: "bob@nowhere.test"}
  bob = PersonStore.update! bob, %{email: "bob2@nowhere.test"}
  PersonStore.delete bob

  # Using Keyword List
  bob = PersonStore.insert! name: "Bob", email: "bob@nowhere.test"
  bob = PersonStore.update! bob, email: "bob2@nowhere.test"

  # Updates/deletes can also occur by id.
  PersonStore.update! 12, %{email: "bob2@nowhere.test"}
  PersonStore.delete 12

  # Update or create
  attributes_to_update = 
  query = %{name: "Bob"}
  PersonStore.update_or_create attributes_to_update, query
  PersonStore.update_or_create! %{email: "new@nowhere.test"}, name: "Bob"
  ```

  ## Changesets ##

  The `insert` and `update` functions by default use a changeset on the provided schema name `:changeset` for inserting and updating.
  This can be overridden and a specific changeset name provided.

  ```elixir
  bob = PersonStore.insert! %{name: "Bob", email: "bob@nowhere.test"}, changeset: :insert_changeset
  bob = PersonStore.insert! [name: "Bob", email: "bob@nowhere.test"], changeset: :insert_changeset
  bob = PersonStore.update! bob, %{email: "bob2@nowhere.test"}, changeset: :update_changeset
  bob = PersonStore.update! bob, [email: "bob2@nowhere.test"], changeset: :update_changeset
  bob = PersonStore.update! bob, %{email: "bob2@nowhere.test"}, changeset: :my_other_custom_changeset
  ``` 

  It is also possible to pass a function reference in as the changeset.

  ```elixir
  def my_changeset(model, params) do
    model
    |> cast(params, [:name, :email])
    |> validate_required([:name])
  end

  insert [name: "Bob"], changeset: &my_changeset/2
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

  ## Filter or Params Map/Keyword List ##

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

  ## Lexical Atom Query ##

  The store provides a function for taking a lexical query atom with a list of values and
  returning the results. Currently only supports `_and_` clauses.

  Functions:

  * `get_all_by`              - Return all results. Equivalent to using the `all` function.
  * `get_by`                  - Return a single result. Equivalent to using the `one` function.

  ```elixir
  # Regular
  PersonStore.all %{name: "Bob", email: "bob@nowhere.test"}
  # Lexical Atom
  PersonStore.get_all_by :name_and_email, ["Bob", "bob@nowhere.test"]

  # Regular
  PersonStore.one %{name: "Bob", email: "bob@nowhere.test"}
  # Lexical Atom
  PersonStore.get_by :name_and_email, ["Bob", "bob@nowhere.test"]
  ```

  ## Generator Factories ##

  Sometimes, such as in unit testing, a developer would like to create a common predefined data structure
  to work against. Generator Factories provide a composable method to create such a data structure. There
  two types of factory methods that can be used. One to create a common factory base for the store and
  another to append upon that base if it is used. The base factory is optional and not required.

  If a default factory does not exist then the defaults will be used as defined in the Struct ecto will
  generate for the schema.

  Macros:

  * `factory`               - Generates a factory segment of values. When no name is provided the fatcory is the automatic base for all factories.

  Functions:

  * `generate`              - Takes a list of atoms and generates a new record in the database based upon the factories matching the atom.
  * `generate!`             - Like `generate` but throws the error instead of returning a tuple.
  * `generate_default`      - Like `generate` but only applies the base factory. When no base is defined, uses the defaults from the Struct Ecto generates.
  * `generate_default!`     - Like `generate_default` but throws the error instead of returning a tuple.

  ```elixir
  defmodule PersonStore do
    use EctoSchemaStore, schema: Person, repo: MyApp.Repo

    # Create the common base for starting factory generated record.
    factory do
      %{
        name: "Test Person",
        email: "test@nowhere.test"
      }
    end

    # Create a factory segment to override the base factory values.
    factory bob do
      %{
        name: "Bob"
      }
    end

    factory karen do
      %{
        name: "Karen"
      }
    end
  end

  # Sample Usage

  # Using just the base
  %Person{name: "Test Person", email: "test@nowhere.test"} = PersonStore.generate!
  {:ok, %Person{name: "Test Person", email: "test@nowhere.test"}} = PersonStore.generate

  # Using bob Factory
  %Person{name: "Bob", email: "test@nowhere.test"} = PersonStore.generate! :bob

  # Using karen factory
  %Person{name: "Karen", email: "test@nowhere.test"} = PersonStore.generate! :karen

  # Using multiple factories, each is overlayed in order.
  %Person{name: "Karen", email: "test@nowhere.test"} = PersonStore.generate! [:bob, :karen]
  %Person{name: "Bob", email: "test@nowhere.test"} = PersonStore.generate! [:karen, :bob]

  # Manually setting values
  %Person{name: "Test Person", email: "ignore@nowhere.test"} = PersonStore.generate_default! email: "ignore@nowhere.test"
  %Person{name: "Bob", email: "bob@nowhere.test"} = PersonStore.generate! :bob, email: "bob@nowhere.test"
  %Person{name: "Karen", email: "karen@nowhere.test"} = PersonStore.generate! [:bob, :karen], email: "karen@nowhere.test"
  ```

  ## Edit Events ##

  A store supports the concept of an event after an edit action is successful in the Ecto repo.

  Events:

  * `:after_insert`
  * `:after_update`
  * `:after_delete`

  ```elixir
  defmodule PersonStore do
    use EctoSchemaStore, schema: Person, repo: MyApp.Repo

    on(:after_delete, model) do
      IO.inspect "Delete \#{schema} id: \#{model.id}"
    end

    on([:after_insert, :after_update], model) do
      IO.inspect "Changed \#{schema} id: \#{model.id}"
    end
  end
  ```
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
      require EctoSchemaStore.Event
      require EctoSchemaStore.Factory
      import EctoSchemaStore.Event, only: [on: 3]
      import EctoSchemaStore.Alias
      import Ecto.Changeset
      import Ecto.Query, except: [update: 3, update: 2]
      import EctoSchemaStore.Factory
      alias unquote(repo), as: Repo
      alias Ecto.Query

      @doc """
      Returns a reference to the schema module `#{unquote(schema)}`.
      """
      def schema, do: unquote(schema)
      @doc """
      Returns a reference to the Ecto Repo module `#{unquote(repo)}`.
      """
      def repo, do: unquote(repo)

      EctoSchemaStore.Event.build
      EctoSchemaStore.Alias.build
      EctoSchemaStore.BuildQueries.build(unquote(schema))
      EctoSchemaStore.Fetch.build(unquote(schema), unquote(repo))
      EctoSchemaStore.Edit.build(unquote(schema), unquote(repo))
      EctoSchemaStore.Factory.build
    end
  end

end
