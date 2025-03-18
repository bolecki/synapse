defmodule Synapse.Admin.Truth do
  use Ecto.Schema
  import Ecto.Changeset

  schema "truths" do
    field :name, :string
    field :position, :integer

    belongs_to :event, Synapse.Admin.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(truth, attrs) do
    truth
    |> cast(attrs, [:name, :position])
    |> validate_required([:name, :position])
  end
end
