defmodule Synapse.Repo.Migrations.CreateRankedPredictions do
  use Ecto.Migration

  def change do
    create table(:ranked_predictions) do
      add :name, :string
      add :position, :integer
      add :event_id, references(:events, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
