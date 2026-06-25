defmodule TodookieWeb.BoardBuilderLive do
  alias Todookie.Todos
  alias Todookie.Board
  use TodookieWeb, :live_view

  def render(assigns) do
    ~H"""
    <%!-- <ul class="p-1 w-full flex items-center gap-2">
      <li> --%>
    <div class="mx-4">
      <.form phx-change="navigate-to-board" for={%{}}>
        <select id="board-picker" name="board" class="select lg:w-sm">
          <option selected></option>
          <option
            :for={board <- @boards}
            value={board.id}
            phx-value-board_id={board.id}
          >
            {board.name}
          </option>
        </select>
      </.form>
    </div>
    <%!-- </li>
    </ul> --%>
    <div class="flex mt-16 mx-6 items-center justify-center">
      <div class="h-32 w-128">
        <.form
          for={@form}
          phx-change="validate-board"
          phx-submit="create-board"
        >
          <.input type="text" label="Name" field={@form[:name]} phx-debounce="300" />
          <.button
            type="submit"
            class="btn rounded bg-blue-600 px-3 py-2 text-white"
          >
            Save
          </.button>
        </.form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:boards, Todos.boards(socket.assigns.current_scope))
      |> assign(:form, to_form(%{"name" => ""}, as: :board))

    {:ok, socket}
  end

  def handle_event("validate-board", %{"board" => board_params}, socket) do
    form =
      %Board{}
      |> Todos.change_board(board_params, socket.assigns.current_scope)
      |> to_form(action: :validate, as: :board)

    socket =
      socket
      |> assign(:new_card_form, form)

    {:noreply, socket}
  end

  def handle_event("create-board", %{"board" => board_params}, socket) do
    case Todos.create_board(board_params, socket.assigns.current_scope) do
      {:ok, board} ->
        socket =
          socket
          |> push_navigate(to: ~p"/boards/#{board.id}")

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:new_card_form, to_form(changeset, as: :board))

        {:noreply, socket}
    end
  end

  def handle_event("navigate-to-board", %{"board" => board_id}, socket) do
    board_id = String.to_integer(board_id)

    socket =
      socket
      |> push_navigate(to: ~p"/boards/#{board_id}")

    {:noreply, socket}
  end
end
