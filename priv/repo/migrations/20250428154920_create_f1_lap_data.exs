defmodule Synapse.Repo.Migrations.CreateF1LapData do
  use Ecto.Migration

  def change do
    create table(:f1_lap_data) do
      add :year, :string, null: false
      add :round, :string, null: false
      add :data, :jsonb, null: false

      timestamps()
    end

    # Create a unique index on year and round to ensure we don't have duplicate entries
    create unique_index(:f1_lap_data, [:year, :round])
  end
end
