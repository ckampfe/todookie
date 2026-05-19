defmodule Todookie.Repo.Migrations.CreateColumns do
  use Ecto.Migration

  def change do
    create table(:columns) do
      add :name, :string
      add :position, :integer, null: false
      add :board_id, references(:boards, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:columns, [:user_id])

    create index(:columns, [:board_id])

    create unique_index(:columns, [:name, :board_id])
  end
end
