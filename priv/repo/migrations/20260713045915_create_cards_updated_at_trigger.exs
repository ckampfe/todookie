defmodule Todookie.Repo.Migrations.CreateCardsUpdatedAtTrigger do
  use Ecto.Migration

  def up do
    execute """
    create trigger cards_updated_at
    after update on cards for each row
    begin
        update cards
        set updated_at = current_timestamp
        where id = old.id;
    end;
    """
  end

  def down do
    execute """
    drop trigger cards_updated_at;
    """
  end
end
