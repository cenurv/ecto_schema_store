defmodule EctoSchemaStore.Utils do
  @moduledoc false

  def remove_from_map(map, key) do
    case Map.pop(map, key) do
      {_, result} -> result
    end
  end

  defp is_assoc(%Ecto.Association.NotLoaded{}), do: true
  defp is_assoc(_), do: false

  @doc """
  Returns non-virtual or association field names.
  """
  def keys(schema, only_assocs \\ false)
    if only_assocs do
      schema.__schema__(:associations)
    else
      schema.__schema__(:fields)
    end
  end

  @doc """
  Append errors to list of errors.
  Takes a prefix to append to the front of the error field name.
  Crude errors are errors that have not been appended yet.

  ## Examples
      iex> Utils.Services.ErrorService.append_errors([{:household_id, {"is missing", []}}], "prefix", %{"field" => ["is invalid"]})
      %{"prefix.household_id" => ["is missing"], "field" => ["is invalid"]}
  """
  def append_errors([], _, errors), do: errors
  def append_errors([error | tail], prefix, errors) do
    {field, message} = error
    message = translate_error(message)
    append_errors(tail, prefix, Map.merge(errors, %{prefix <> "." <> Atom.to_string(field) => [message]}))
  end

  @doc """
  Append errors to list of errors.
  Crude errors are errors that have not been appended yet.

  ## Examples
      iex> Utils.Services.ErrorService.append_errors([{:household_id, {"is missing", []}}], %{"field" => ["is invalid"]})
      %{"household_id" => ["is missing"], "field" => ["is invalid"]}
  """
  def append_errors([], errors), do: errors
  def append_errors([error | tail], errors) do
    {field, message} = error
    message = translate_error(message)
    append_errors(tail, Map.merge(errors, %{Atom.to_string(field) => [message]}))
  end

  @doc """
  Translate ecto changeset errors into human readable. This handles string interpolation

  ## Examples
      iex> Utils.Services.ErrorService.translate_error({"can't be blank", []})
      "can't be blank"
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(EctoSchemaStore.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(EctoSchemaStore.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Converts a changeset and all child changesets to a stuctured map.
  """
  def interpret_errors(changeset, name \\ "root", acc \\ %{})
  def interpret_errors(changeset, name, acc) when is_boolean(name), do: interpret_errors changeset, "root", acc
  def interpret_errors(changeset, name, acc) when is_atom(name), do: interpret_errors changeset, Atom.to_string(name), acc
  def interpret_errors(%Ecto.Changeset{changes: changes, errors: errors}, name, acc) do
    error_list = for key <- Map.keys changes do
      interpret_errors changes[key], "#{name}.#{key}", acc
    end

    # Filter out children without errors.
    error_list = Enum.filter error_list, fn(entry) -> entry != %{} end

    # Flatten into single map.
    acc = Enum.reduce error_list, acc, fn(entry, sub) -> Map.merge sub, entry end

    # Process the errors for this level.
    append_errors errors, name, acc
  end
  def interpret_errors(value, name, acc) when is_list value do
    interpret_errors_from_list value, name, acc
  end
  def interpret_errors(_, _, _), do: %{}

  def interpret_errors_from_list(value, name, acc, index \\ 0)
  def interpret_errors_from_list([], _name, acc, _index), do: acc
  def interpret_errors_from_list([h | t], name, acc, index) do
    error_output = interpret_errors(h, "#{name}[#{index}]", acc)
    interpret_errors_from_list(t, name, error_output, index + 1)
  end

end
