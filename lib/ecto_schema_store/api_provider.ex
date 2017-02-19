defmodule EctoSchemaStore.ApiProvider do
  use RestApiBuilder.Provider

  defmacro generate(opts) do
    store = Keyword.get opts, :store, nil
    parent_field = Keyword.get opts, :parent, nil
    {soft_delete_field, soft_delete_value} = Keyword.get opts, :soft_delete, {:deleted, true}
    include = Keyword.get opts, :include, []
    exclude = Keyword.get opts, :exclude, []
    preload = Keyword.get opts, :preload, []

    parent_field =
      if is_binary parent_field do
        String.to_atom parent_field
      else
        parent_field
      end

    quote do
      import EctoSchemaStore.ApiProvider

      def store, do: unquote(store)

      defp whitelist(models) when is_list models do
        Enum.map models, fn(model) -> whitelist model end
      end
      defp whitelist(model) do
        keys = EctoSchemaStore.Utils.keys unquote(store).schema
        include = unquote(include)
        exclude = unquote(exclude)

        keys =
          keys
          |> Enum.concat(include)
          |> Enum.reject(&(&1 in exclude))

        Map.take model, keys
      end

      defp fetch_all(%Plug.Conn{assigns: %{current: parent}} = conn) do
        parent_field = unquote(parent_field)

        if parent && parent_field do
          query =
            []
            |> append_exclude_deleted
            |> Keyword.put(parent_field, parent.id)

          unquote(store).all query, preload: unquote(preload) 
        else
          unquote(store).all append_exclude_deleted([]), preload: unquote(preload) 
        end
      end
      defp fetch_all(conn) do
        unquote(store).all append_exclude_deleted([]), preload: unquote(preload) 
      end

      defp has_field?(field), do: field in unquote(store).schema_fields

      defp append_exclude_deleted(params_list) when is_list params_list do
        if has_field?(unquote(soft_delete_field)) do
          Keyword.put params_list, unquote(soft_delete_field), {:!=, unquote(soft_delete_value)}
        else
          params_list
        end
      end
      defp append_exclude_deleted(params), do: params

      def preload(%Plug.Conn{path_params: %{"id" => id}, assigns: assigns} = conn) do
        parent_field = unquote(parent_field)
        resources = assigns[:resources]

        {parent, _href} = List.last(resources || [{nil, nil}])
        current =
          if parent && parent_field do
            query =
              [id: id]
              |> append_exclude_deleted
              |> Keyword.put(parent_field, parent.id)

            unquote(store).one query, preload: unquote(preload) 
          else
            unquote(store).one append_exclude_deleted([id: id]), preload: unquote(preload) 
          end

        validated =
          cond do
            is_nil(current) -> false
            is_nil(parent) or is_nil(parent_field) -> true
            true -> true
          end

        if validated do
          conn
          |> append_resource(current)
          |> assign(:parent, parent)
          |> assign(:current, current)
        else
          conn |> send_errors(404, "Not Found") |> Plug.Conn.halt
        end
      end

      def show(%Plug.Conn{assigns: %{current: model}} = conn) do
        case conn.assigns.current do
          nil -> send_errors conn, 404, "Not Found"
          model -> send_resource conn, whitelist(unquote(store).to_map(model))
        end
      end
      def show(conn), do: send_errors conn, 404, "Not Found"

      def index(conn) do
        records = fetch_all conn
        send_resource conn, whitelist(unquote(store).to_map(records))
      end

      def create(%Plug.Conn{assigns: assigns} = conn) do
        parent_field = unquote(parent_field)
        parent = assigns[:current]
        changeset = __use_changeset__ conn, :create

        params =
          if parent && parent_field do
            conn.body_params
            |> Map.put(parent_field, parent.id)
          else
            conn.body_params
          end

        response = unquote(store).insert params, changeset: changeset, errors_to_map: singular_name()

        case response do
          {:error, message} -> send_errors conn, 400, message
          {:ok, record} -> send_resource conn, whitelist(unquote(store).to_map(record))
        end
      end

      def update(%Plug.Conn{assigns: assigns} = conn) do
        current = assigns[:current]

        case current do
          nil -> send_errors conn, 404, "Not Found"
          model ->
            changeset = __use_changeset__ conn, :update
            response = unquote(store).update model, conn.body_params, changeset: changeset, errors_to_map: singular_name()

            case response do
              {:error, message} -> send_errors conn, 400, message
              {:ok, record} -> send_resource conn, whitelist(unquote(store).to_map(record))
            end
        end
      end

      def delete(%Plug.Conn{assigns: assigns} = conn) do
        current = assigns[:current]

        case current do
          nil -> send_errors conn, 404, "Not Found"
          model ->
            if has_field?(unquote(soft_delete_field)) do
              current = assigns[:current]
              response = unquote(store).update_fields(current, Keyword.put([], unquote(soft_delete_field), unquote(soft_delete_value)), errors_to_map: singular_name())

              case response do
                  {:error, message} -> send_errors conn, 400, message
                  {:ok, record} -> send_resource conn, nil
              end
            else
              unquote(store).delete model
              send_resource conn, nil
            end
        end
      end

      def __use_changeset__(_, _), do: :changeset

      defoverridable [__use_changeset__: 2, index: 1, show: 1, create: 1, update: 1, delete: 1]
    end
  end

  defmacro changeset(name) do
    quote do
      changeset unquote(name), :all
    end
  end

  defmacro changeset(name, :all) do
    quote do
      changeset unquote(name), [:create, :update]
    end
  end
  defmacro changeset(name, actions) when is_list actions do
    for action <- actions do
      quote do
        changeset unquote(name), unquote(action)
      end
    end
  end
  defmacro changeset(name, action) when is_binary action do
    quote do
      changeset unquote(name), String.to_atom(unquote(action))
    end
  end
  defmacro changeset(name, action) when is_binary name do
    quote do
      changeset String.to_atom(unquote(name)), unquote(action)
    end
  end
  defmacro changeset(name, action) when is_atom(action) and is_atom(name) do
    quote do
      def __use_changeset__(conn, unquote(action)) do
        override_changeset = conn.assigns[:changeset]
        override_changeset || unquote(name)
      end
    end
  end
end
