defmodule Synapse.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :name, :string
      add :season_id, references(:seasons, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
