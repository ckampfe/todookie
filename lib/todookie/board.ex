defmodule Todookie.Board do
  use Ecto.Schema
  import Ecto.Changeset

  schema "boards" do
    field :name, :string
    field :user_id, :id

    has_many :columns, Todookie.Column

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(board, attrs, user_scope) do
    board
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> put_change(:user_id, user_scope.user.id)
  end
end
