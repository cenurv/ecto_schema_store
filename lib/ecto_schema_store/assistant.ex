defmodule EctoSchemaStore.Assistant do
  @moduledoc """
  Provides macros to customize configuration aspects of a store module.
  """

  @doc """
  Creates variations of the existing edit functions with a predefined configuration.

  Functions preconfigured:

  * `insert`
  * `insert!`
  * `insert_fields`
  * `insert_fields!`
  * `validate_insert`
  * `update`
  * `update!`
  * `update_fields`
  * `update_fields!`
  * `validate_update`

  If using the name `api` the follwing functions will be generate:

  * `insert_api`
  * `insert_api!`
  * `insert_fields_api`
  * `insert_fields_api!`
  * `validate_insert_api`
  * `update_api`
  * `update_api!`
  * `update_fields_api`
  * `update_fields_api!`
  * `validate_update_api`
  """
  defmacro preconfigure(name, predefined_options \\ []) when is_atom(name) and is_list(predefined_options) do
    quote do
      preconfigure_insert unquote(name), unquote(predefined_options), "_", ""
      preconfigure_insert unquote(name), unquote(predefined_options), "_", "!"
      preconfigure_insert unquote(name), unquote(predefined_options), "_fields_", ""
      preconfigure_insert unquote(name), unquote(predefined_options), "_fields_", "!"
      preconfigure_update unquote(name), unquote(predefined_options), "_", ""
      preconfigure_update unquote(name), unquote(predefined_options), "_", "!"
      preconfigure_update unquote(name), unquote(predefined_options), "_fields_", ""
      preconfigure_update unquote(name), unquote(predefined_options), "_fields_", "!"
      preconfigure_validate unquote(name), unquote(predefined_options)
    end
  end

  @doc """
  Creates a preconfigured version of an existing edit function.

  ```elixir
  preconfigure_insert :api, changeset: :mychangeset
  preconfigure_insert :api, [changeset: :mychangeset], "_fields_", "!",

  insert_api name: "Sample"
  insert_api_fields! name: "Sample"
  ```
  """
  defmacro preconfigure_insert(name, predefined_options \\ [], action_prefix \\ "_", action_suffix \\ "") when is_atom(name) and is_list(predefined_options) do
    new_name = String.to_atom("insert#{action_prefix}#{name}#{action_suffix}")
    action_prefix = String.replace_suffix action_prefix, "_", ""
    callable = String.to_atom("insert#{action_prefix}#{action_suffix}")

    quote do
      @doc """
      Inserts a record to the `#{unquote(callable)}` function with the following
      predfined options.

      ```elixir
      #{unquote(inspect predefined_options)}
      ```

      Using:

      ```elixir
      preconfigure :api, changeset: :mychangeset, errors_to_map: :my_record

      # Basic Insert
      #{unquote(new_name)} name: "Sample"

      # Override predefined options
      #{unquote(new_name)} [name: "Sample"], changeset: :otherchangeset
      ```
      """
      def unquote(new_name)(params, opts \\ []) do
        options = Keyword.merge unquote(predefined_options), opts
        unquote(callable)(params, options)
      end
    end
  end

  @doc """
  Creates a preconfigured version of an existing edit function.

  ```elixir
  preconfigure_update :api, changeset: :mychangeset
  preconfigure_update :api, [changeset: :mychangeset], "_fields_", "!",

  update_api name: "Sample"
  update_api_fields! name: "Sample"
  ```
  """
  defmacro preconfigure_update(name, predefined_options \\ [], action_prefix \\ "_", action_suffix \\ "") when is_atom(name) and is_list(predefined_options) do
    new_name = String.to_atom("update#{action_prefix}#{name}#{action_suffix}")
    action_prefix = String.replace_suffix action_prefix, "_", ""
    callable = String.to_atom("update#{action_prefix}#{action_suffix}")

    quote do
      @doc """
      Updates a record to the `#{unquote(callable)}` function with the following
      predfined options.

      ```elixir
      #{unquote(inspect predefined_options)}
      ```

      Using:

      ```elixir
      preconfigure :api, changeset: :mychangeset, errors_to_map: :my_record

      model = insert_api name: "Sample"

      # Basic Update
      #{unquote(new_name)} model, name: "Sample2"

      # Override predefined options
      #{unquote(new_name)} model, [name: "Sample"], changeset: :otherchangeset
      ```
      """
      def unquote(new_name)(schema_or_id, params, opts \\ []) do
        options = Keyword.merge unquote(predefined_options), opts
        unquote(callable)(schema_or_id, params, options)
      end
    end
  end

  defmacro preconfigure_validate(name, predefined_options \\ []) when is_atom(name) and is_list(predefined_options) do
    update_name = String.to_atom("validate_update_#{name}")
    insert_name = String.to_atom("validate_insert_#{name}")

    quote do
      @doc """
      Checks update validation with the following predefined options:

      ```elixir
      #{unquote(inspect predefined_options)}
      ```

      Using:

      ```elixir
      preconfigure :api, changeset: :mychangeset, errors_to_map: :my_record

      model = insert_api name: "Sample"

      # Basic update validation
      #{unquote(update_name)} model, name: "Sample2"

      # Override predefined options validation
      #{unquote(update_name)} model, [name: "Sample"], changeset: :otherchangeset
      ```
      """
      def unquote(update_name)(schema_or_id, params, opts \\ []) do
        options = Keyword.merge unquote(predefined_options), opts
        validate_update(schema_or_id, params, options)
      end

      @doc """
      Checks insert validation with the following predefined options:

      ```elixir
      #{unquote(inspect predefined_options)}
      ```

      Using:

      ```elixir
      preconfigure :api, changeset: :mychangeset, errors_to_map: :my_record

      # Basic update validation
      #{unquote(insert_name)} name: "Sample2"

      # Override predefined options validation
      #{unquote(insert_name)} [name: "Sample"], changeset: :otherchangeset
      ```
      """
      def unquote(insert_name)(params, opts \\ []) do
        options = Keyword.merge unquote(predefined_options), opts
        validate_insert(params, options)
      end
    end
  end
end
