defmodule TodookieWeb.BoardLive do
  require Logger
  alias Todookie.Todos
  alias Todookie.Card
  use TodookieWeb, :live_view
  import TodookieWeb.Modal

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-dvh">
      <ul class="p-1 w-full flex items-center gap-2 mb-4">
        <li>
          <.button
            class="btn inline-block align-middle ml-auto"
            phx-click="new-card"
          >
            <.icon name="hero-plus" />
          </.button>
        </li>
        <li>
          <.form phx-change="navigate-to-board" for={%{}}>
            <select id="board-picker" name="board" class="select w-sm">
              <option value="new-board">new board...</option>
              <option
                :for={board <- @boards}
                value={board.id}
                selected={board.id == @board.id}
                phx-value-board_id={board.id}
              >
                {board.name}
              </option>
            </select>
          </.form>
        </li>
      </ul>
      <div
        id="lists"
        class="grid sm:grid-cols-1 md:grid-cols-3 gap-2 p-2"
      >
        <.live_component
          :for={column <- @board.columns}
          id={"#{column.name}-column"}
          module={TodookieWeb.ListComponent}
          column={column}
          group="grocery_list"
        />
        <.card_new_modal
          columns={@board.columns}
          show={@show_new_card_modal}
          form={@new_card_form}
        />
        <.card_detail_modal card={@card} />
        <.card_edit_modal form={@edit_card_form} />
      </div>
    </div>
    """
  end

  def card_new_modal(assigns) do
    ~H"""
    <.modal id="new-card-modal" show={@show}>
      <:title>new card</:title>
      <.form
        id="new-card-form"
        for={@form}
        phx-change="validate-card"
        phx-submit="create-card"
      >
        <.input
          type="text"
          field={@form[:title]}
          label="Title"
          placeholder="my great card"
        />

        <.input
          type="textarea"
          field={@form[:body]}
          label="Body"
          placeholder="some insightful text"
        />

        <.input
          type="select"
          field={@form[:column_id]}
          label="Column"
          options={for column <- @columns, do: {column.name, column.id}}
        />

        <.button
          type="button"
          phx-click="close-modal"
          class="btn rounded border px-3 py-2"
        >
          Cancel
        </.button>

        <.button
          type="submit"
          class="btn rounded bg-blue-600 px-3 py-2 text-white"
        >
          Save
        </.button>
      </.form>
    </.modal>
    """
  end

  def card_detail_modal(assigns) do
    ~H"""
    <.modal id="card-detail-modal" show={@card}>
      <:title>{@card.title}</:title>
      <div>
        {raw(
          MDEx.to_html!(@card.body || "",
            extension: [
              strikethrough: true,
              tasklist: true,
              autolink: true
            ]
          )
        )}
      </div>
      <:actions>
        <.button
          type="button"
          phx-click="close-modal"
          class="btn rounded border px-3 py-2"
        >
          Cancel
        </.button>
        <.button
          type="submit"
          class="btn rounded bg-blue-600 px-3 py-2 text-white"
          phx-click="edit-card-detail"
        >
          Edit
        </.button>

        <.button
          class="btn btn-error"
          phx-click="delete-card"
          data-confirm={"Delete card \"#{@card.title}?\""}
          phx-value-card_id={@card.id}
          phx-value-column_id={@card.column_id}
        >
          Delete
        </.button>
      </:actions>
    </.modal>
    """
  end

  def card_edit_modal(assigns) do
    ~H"""
    <.modal id="card-edit-modal" show={@form}>
      <:title>Edit</:title>
      <.form
        id="new-card-form"
        for={@form}
        phx-change="validate-card"
        phx-submit="save-card"
      >
        <.input type="text" field={@form[:title]} placeholder="title" />
        <.input type="textarea" field={@form[:body]} placeholder="body" />
        <.input type="hidden" field={@form[:id]} />
        <.input type="hidden" field={@form[:column_id]} />
        <.input type="hidden" field={@form[:position]} />

        <.button
          type="button"
          phx-click="close-modal"
          class="btn rounded border px-3 py-2"
        >
          Cancel
        </.button>

        <.button
          type="submit"
          class="btn rounded bg-blue-600 px-3 py-2 text-white"
        >
          Save
        </.button>
      </.form>
    </.modal>
    """
  end

  def mount(%{"board_id" => board_id}, _session, socket) do
    board =
      Todos.get_board!(board_id, socket.assigns.current_scope)

    socket =
      socket
      |> assign(:boards, Todos.boards(socket.assigns.current_scope))
      |> assign(:board, board)
      |> assign(:show_new_card_modal, false)
      |> assign(:card, false)
      |> assign(:edit_card_form, false)
      |> assign(
        :new_card_form,
        to_form(Todos.change_card(%Card{}, %{}, socket.assigns.current_scope))
      )
      |> assign(:page_title, board.name)

    {:ok, socket}
  end

  def handle_event("new-card", _unsigned_params, socket) do
    socket =
      socket
      |> assign(:show_new_card_modal, true)

    {:noreply, socket}
  end

  def handle_event("save-card", %{"card" => card_params}, socket) do
    case Todos.update_card(
           socket.assigns.card,
           card_params,
           socket.assigns.current_scope
         ) do
      {:ok, card} ->
        socket =
          socket
          |> assign(:card, false)
          |> assign(:edit_card_form, false)
          |> update(:board, fn board ->
            Map.update!(board, :columns, fn columns ->
              column_index =
                Enum.find_index(columns, fn column ->
                  column.id == card.column_id
                end)

              List.update_at(columns, column_index, fn column ->
                Map.update!(column, :cards, fn cards ->
                  cards
                  |> List.delete_at(card.position)
                  |> List.insert_at(card.position, card)
                end)
              end)
            end)
          end)

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:edit_card_form, to_form(changeset))

        {:noreply, socket}
    end
  end

  def handle_event("create-card", %{"card" => card_params}, socket) do
    case Todos.create_card(card_params, socket.assigns.current_scope) do
      {:ok, card} ->
        socket =
          socket
          |> assign(
            :new_card_form,
            to_form(Todos.change_card(%Card{}, %{}, socket.assigns.current_scope))
          )
          |> assign(:show_new_card_modal, false)
          |> update(:board, fn board ->
            Map.update!(board, :columns, fn columns ->
              column_index =
                Enum.find_index(columns, fn column ->
                  column.id == card.column_id
                end)

              List.update_at(columns, column_index, fn column ->
                Map.update!(column, :cards, fn cards ->
                  [card | cards]
                end)
              end)
            end)
          end)

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:new_card_form, to_form(changeset))

        {:noreply, socket}
    end
  end

  def handle_event("validate-card", %{"card" => card_params}, socket) do
    form =
      %Card{}
      |> Todos.change_card(card_params, socket.assigns.current_scope)
      |> to_form(action: :validate)

    socket =
      socket
      |> assign(:new_card_form, form)

    {:noreply, socket}
  end

  def handle_event("delete-card", %{"card_id" => card_id, "column_id" => column_id}, socket) do
    card_id = String.to_integer(card_id)
    column_id = String.to_integer(column_id)

    Todos.delete_card(card_id, socket.assigns.current_scope)

    socket =
      socket
      |> assign(:card, false)
      |> update(:board, fn board ->
        Map.update!(board, :columns, fn columns ->
          column_idx =
            Enum.find_index(columns, fn column ->
              column.id == column_id
            end)

          columns
          |> List.update_at(column_idx, fn column ->
            Map.update!(column, :cards, fn cards ->
              Enum.reject(cards, fn card ->
                card.id == card_id
              end)
            end)
          end)
        end)
      end)

    {:noreply, socket}
  end

  def handle_event("close-modal", _params, socket) do
    socket =
      socket
      |> assign(:card, false)
      |> assign(:edit_card_form, false)
      |> assign(:show_new_card_modal, false)
      |> assign(
        :new_card_form,
        to_form(Todos.change_card(%Card{}, %{}, socket.assigns.current_scope))
      )

    {:noreply, socket}
  end

  def handle_event("edit-card-detail", _unsigned_params, socket) do
    socket =
      socket
      |> assign(
        :edit_card_form,
        to_form(Ecto.Changeset.change(socket.assigns.card))
      )

    {:noreply, socket}
  end

  def handle_event("navigate-to-board", %{"board" => maybe_board_id}, socket) do
    case maybe_board_id do
      "new-board" ->
        socket =
          socket
          |> push_navigate(to: ~p"/boards/new")

        {:noreply, socket}

      board_id ->
        board_id = String.to_integer(board_id)

        socket =
          socket
          |> push_navigate(to: ~p"/boards/#{board_id}")

        {:noreply, socket}
    end
  end

  # figure out why app.js is sending fromposition 0 and toposition 1
  # when a card is moved to its own position in the same column
  def handle_info(
        {:reposition,
         %{
           "card_id" => _card_id,
           "from_index" => from_position,
           "to_index" => to_position,
           "from" => %{"column_id" => from_column_id},
           "to" => %{"column_id" => to_column_id}
         }},
        socket
      )
      when from_position == to_position and from_column_id == to_column_id do
    Logger.debug("NO OP MOVE")
    {:noreply, socket}
  end

  def handle_info(
        {:reposition,
         %{
           "card_id" => card_id,
           "from_index" => from_position,
           "to_index" => to_position,
           "from" => %{"column_id" => from_column_id},
           "to" => %{"column_id" => to_column_id}
         }},
        socket
      ) do
    card_id = String.to_integer(card_id)
    from_column_id = String.to_integer(from_column_id)
    to_column_id = String.to_integer(to_column_id)

    {:ok, moved_card} =
      Todos.move_card(
        card_id,
        from_column_id,
        from_position,
        to_column_id,
        to_position,
        socket.assigns.current_scope
      )

    socket =
      socket
      |> update(:board, fn board ->
        Map.update!(board, :columns, fn columns ->
          from_column_idx =
            Enum.find_index(columns, fn column ->
              column.id == from_column_id
            end)

          to_column_id =
            Enum.find_index(columns, fn column ->
              column.id == to_column_id
            end)

          columns
          |> List.update_at(from_column_idx, fn column ->
            Map.update!(column, :cards, fn cards ->
              Enum.reject(cards, fn card ->
                card.id == card_id
              end)
            end)
          end)
          |> List.update_at(to_column_id, fn column ->
            Map.update!(column, :cards, fn cards ->
              List.insert_at(cards, to_position, moved_card)
            end)
          end)
        end)
      end)

    {:noreply, socket}
  end

  def handle_info({:double_click, %{"id" => _id, "kind" => "column"}} = params, socket) do
    IO.inspect(params, label: "double click column params from board liveview")
    {:noreply, socket}
  end

  def handle_info(
        {:double_click, %{"id" => "card-" <> card_id, "kind" => "card"}} = params,
        socket
      ) do
    IO.inspect(params, label: "double click card params from board liveview")
    card_id = String.to_integer(card_id)

    card =
      Todos.get_card!(card_id, socket.assigns.current_scope)

    socket =
      socket
      |> assign(:card, card)

    {:noreply, socket}
  end
end
