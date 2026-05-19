defmodule Todookie.Column do
  use Ecto.Schema
  import Ecto.Changeset

  schema "columns" do
    field :name, :string
    field :position, :integer
    field :user_id, :id

    belongs_to :board, Todookie.Board
    has_many :cards, Todookie.Card

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(column, attrs, user_scope) do
    column
    |> cast(attrs, [:name, :position, :board_id])
    |> validate_required([:name, :board_id])
    |> put_change(:user_id, user_scope.user.id)
  end
end
