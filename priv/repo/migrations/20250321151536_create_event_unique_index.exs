defmodule Synapse.Repo.Migrations.CreateEventUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:events, [:season_id, :name])
  end
end
