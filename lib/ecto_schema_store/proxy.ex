defmodule EctoSchemaStore.Proxy do
  @moduledoc """
  Generates proxy functions that pass off to the desired store module.

  When used with a schema module, this is usually not possible with import because
  we the store cannot be compiled until the schema is compiled. But the schema
  cannot import until the store is compiled, so generally, the functions cannot
  be brought into the store directly. Thbis solution works around that and allows the functions
  to be public so that you can call the store functions on the schema module.

  You cannot use multiple store modules at once as that each would override the others.
  There is no requirement to place this on the schema module, it can be included in any
  Elixir module.

  Functions Included:

  * `one`
  * `all`
  * `insert`
  * `insert!`
  * `insert_fields`
  * `insert_fields!`
  * `update`
  * `update!`
  * `update_fields`
  * `update_fields!`
  * `update_or_create`
  * `update_or_create!`
  * `update_or_create_fields`
  * `update_or_create_fields!`
  * `delete`
  * `delete!`
  * `delete_all`
  * `generate`
  * `generate!`
  * `generate_default`
  * `generate_default!`
  * `exists?`
  * `to_map`
  * `count_records`
  * `preload_assocs`
  * `find_or_create`
  * `find_or_create!`
  * `find_or_create_fields`
  * `find_or_create_fields!`
  * `validate_insert`
  * `validate_update`
  * `transaction`
  * `refresh`

  ```
  defmodule Person do
    use Ecto.Schema
    use EctoSchemaStore.proxy, module: PersonStore
  end
  ```
  """

  @proxiable_functions [
                        one: 1, one: 2,
                        all: 0, all: 1, all: 2,
                        insert: 0, insert: 1, insert: 2,
                        insert!: 1, insert!: 2,
                        insert_fields: 1, insert_fields: 2,
                        insert_fields!: 1, insert_fields!: 2,
                        update: 0, update: 1, update: 2,
                        update!: 1, update!: 2,
                        update_fields: 1, update_fields: 2,
                        update_fields!: 1, update_fields!: 2,
                        update_or_create: 2, update_or_create: 3,
                        update_or_create!: 2, update_or_create!: 3,
                        update_or_create_fields: 2, update_or_create_fields!: 2,
                        delete: 1, delete: 2,
                        delete!: 1, delete!: 2,
                        delete_all: 0, delete_all: 1, delete_all: 2,
                        generate: 0, generate: 1, generate: 2,
                        generate!: 0, generate!: 1, generate!: 2,
                        generate_default: 0, generate_default: 1,
                        generate_default!: 0, generate_default!: 1,
                        exists?: 1,
                        to_map: 1,
                        count_records: 0, count_records: 1,
                        preload_assocs: 2,
                        find_or_create: 2, find_or_create: 3,
                        find_or_create!: 2, find_or_create!: 3,
                        find_or_create_fields: 2, find_or_create_fields!: 2,
                        validate_insert: 1, validate_insert: 2,
                        validate_update: 2, validate_update: 3,
                        transaction: 1,
                        refresh: 1
                       ]

  defmacro __using__(opts) do
    module = Keyword.get opts, :store
    functions = @proxiable_functions

    setup =
      if is_nil module do
        quote do
          @__store_module__ String.to_atom "#{__MODULE__}.Store"
        end
      else
        quote do
          @__store_module__ module
        end
      end

    store_access =
      quote do
        def store do
          @__store_module__
        end
      end

    functions =
      for {function, arguments} <- functions do
        generate(function, arguments)
      end

    [setup, store_access] ++ functions
  end

  def generate(function, arguments)
  def generate(function, 0) do
    quote do
      def unquote(function)() do
        apply(@__store_module__, unquote(function), [])
      end
    end
  end
  def generate(function, 1) do
    quote do
      def unquote(function)(arg1) do
        apply(@__store_module__, unquote(function), [arg1])
      end
    end
  end
  def generate(function, 2) do
    quote do
      def unquote(function)(arg1, arg2) do
        apply(@__store_module__, unquote(function), [arg1, arg2])
      end
    end
  end
  def generate(function, 3) do
    quote do
      def unquote(function)(arg1, arg2, arg3) do
        apply(@__store_module__, unquote(function), [arg1, arg2, arg3])
      end
    end
  end
end
