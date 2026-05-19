defmodule Todookie.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :title, :string, null: false
      add :body, :string
      add :position, :integer, null: false
      add :column_id, references(:columns, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:cards, [:user_id])

    create index(:cards, [:column_id])

    create index(:cards, [:position])
  end
end
