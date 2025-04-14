defmodule Synapse.Repo.Migrations.AddAdminToProfiles do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      add :admin, :boolean, default: false, null: false
    end
  end
end
