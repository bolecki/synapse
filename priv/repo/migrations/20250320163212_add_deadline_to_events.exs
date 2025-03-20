defmodule Synapse.Repo.Migrations.AddDeadlineToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :deadline, :utc_datetime
    end
  end
end
