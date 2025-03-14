defmodule Synapse.Admin.RankedPrediction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ranked_predictions" do
    field :name, :string
    field :position, :integer

    belongs_to :event, Synapse.Admin.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ranked_prediction, attrs) do
    ranked_prediction
    |> cast(attrs, [:name, :position])
    |> validate_required([:name, :position])
  end
end
