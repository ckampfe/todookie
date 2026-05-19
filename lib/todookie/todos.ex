defmodule Todookie.Todos do
  alias Todookie.Column
  alias Todookie.Board
  alias Todookie.Card
  alias Todookie.Repo

  import Ecto.Query

  def get_board!(id, user_scope) do
    cards_query =
      Card
      |> order_by([c], c.position)

    Board
    |> where([b], b.user_id == ^user_scope.user.id)
    |> preload(columns: [cards: ^cards_query])
    |> Repo.get!(id)
  end

  def change_board(board, params, user_scope) do
    Board.changeset(board, params, user_scope)
  end

  def create_board(params, user_scope) do
    Repo.transact(fn ->
      with {:ok, board} <- %Board{} |> change_board(params, user_scope) |> Repo.insert(),
           {:ok, _column1} <-
             create_column(%{"name" => "Todo", "board_id" => board.id}, user_scope),
           {:ok, _column2} <-
             create_column(%{"name" => "Doing", "board_id" => board.id}, user_scope),
           {:ok, _column3} <-
             create_column(%{"name" => "Done", "board_id" => board.id}, user_scope) do
        {:ok, board}
      end
    end)
  end

  def create_board!(params, user_scope) do
    %Board{}
    |> change_board(params, user_scope)
    |> Repo.insert!()
  end

  def boards(user_scope) do
    Board
    |> where([b], b.user_id == ^user_scope.user.id)
    |> order_by([b], desc: b.updated_at)
    |> Repo.all()
  end

  def change_column(column, params, user_scope) do
    Column.changeset(column, params, user_scope)
  end

  def create_column(%{"board_id" => board_id} = params, user_scope) do
    {:ok, column} =
      Repo.transact(fn ->
        max_position =
          Column
          |> where([c], c.board_id == ^board_id)
          |> group_by([c], c.board_id)
          |> select([c], coalesce(max(c.position), 0))
          |> Repo.one()

        new_position =
          if max_position do
            max_position + 1
          else
            0
          end

        {:ok,
         %Column{}
         |> change_column(Map.put(params, "position", new_position), user_scope)
         |> Repo.insert()}
      end)

    column
  end

  def create_column!(%{"board_id" => board_id} = params, user_scope) do
    {:ok, column} =
      Repo.transact(fn ->
        max_position =
          Column
          |> where([c], c.board_id == ^board_id)
          |> group_by([c], c.board_id)
          |> select([c], coalesce(max(c.position), 0))
          |> Repo.one()

        new_position =
          if max_position do
            max_position + 1
          else
            0
          end

        {:ok,
         %Column{}
         |> change_column(Map.put(params, "position", new_position), user_scope)
         |> Repo.insert!()}
      end)

    column
  end

  def get_card!(id, user_scope) do
    Card
    |> where([c], c.user_id == ^user_scope.user.id)
    |> Repo.get!(id)
  end

  def change_card(card, params, user_scope) do
    Card.changeset(card, params, user_scope)
  end

  def create_card(%{"column_id" => column_id} = params, user_scope) do
    Repo.transact(fn ->
      max_position =
        Card
        |> where([c], c.column_id == ^column_id)
        |> group_by([c], c.column_id)
        |> select([c], coalesce(max(c.position), 0))
        |> Repo.one()

      new_position =
        if max_position do
          max_position + 1
        else
          0
        end

      %Card{}
      |> change_card(Map.put(params, "position", new_position), user_scope)
      |> Repo.insert()
    end)
  end

  def create_card!(%{"column_id" => column_id} = params, user_scope) do
    Repo.transact(fn ->
      max_position =
        Card
        |> where([c], c.column_id == ^column_id)
        |> group_by([c], c.column_id)
        |> select([c], max(c.position))
        |> Repo.one()

      new_position =
        if max_position do
          max_position + 1
        else
          0
        end

      {:ok,
       %Card{}
       |> change_card(Map.put(params, "position", new_position), user_scope)
       |> Repo.insert!()}
    end)
  end

  def update_card(card, params, user_scope) do
    card
    |> change_card(params, user_scope)
    |> Repo.update()
  end

  def move_card(card_id, from_column_id, from_position, to_column_id, to_position, user_scope) do
    Repo.transact(fn ->
      # update the from_column's remaining cards
      Card
      |> where([c], c.column_id == ^from_column_id)
      |> where([c], c.id != ^card_id)
      |> where([c], c.position >= ^from_position)
      |> where([c], c.position > 0)
      |> where([c], c.user_id == ^user_scope.user.id)
      |> update([c], set: [position: c.position - 1])
      |> Repo.update_all([])

      # update_the to_column's remaining_cards
      Card
      |> where([c], c.column_id == ^to_column_id)
      |> where([c], c.user_id == ^user_scope.user.id)
      |> where([c], c.position >= ^to_position)
      |> update([c], set: [position: c.position + 1])
      |> Repo.update_all([])

      # update the card's new column and position
      Card
      |> where([c], c.id == ^card_id)
      |> where([c], c.user_id == ^user_scope.user.id)
      |> update([c], set: [column_id: ^to_column_id, position: ^to_position])
      |> Repo.update_all([])

      {:ok, get_card!(card_id, user_scope)}
    end)
  end

  def delete_card(card_id, user_scope) do
    Card
    |> where([c], c.id == ^card_id)
    |> where([c], c.user_id == ^user_scope.user.id)
    |> Repo.delete_all()
  end
end
