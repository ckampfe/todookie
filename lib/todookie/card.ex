defmodule Todookie.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :title, :string
    field :body, :string
    field :position, :integer
    field :user_id, :id

    belongs_to :column, Todookie.Column

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(card, attrs, user_scope) do
    card
    |> cast(attrs, [:title, :body, :position, :column_id])
    |> validate_required([:title, :column_id])
    |> put_change(:user_id, user_scope.user.id)
  end
end
