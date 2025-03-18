defmodule Synapse.Repo.Migrations.CreateTruths do
  use Ecto.Migration

  def change do
    create table(:truths) do
      add :name, :string
      add :position, :integer
      add :event_id, references(:events, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:truths, [:event_id, :name])
  end
end
