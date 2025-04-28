defmodule Synapse.F1LapData do
  @moduledoc """
  Schema and functions for F1 lap data storage.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Synapse.Repo

  schema "f1_lap_data" do
    field :year, :string
    field :round, :string
    field :data, :map

    timestamps()
  end

  @doc """
  Creates a changeset for F1 lap data.
  """
  def changeset(f1_lap_data, attrs) do
    f1_lap_data
    |> cast(attrs, [:year, :round, :data])
    |> validate_required([:year, :round, :data])
    |> unique_constraint([:year, :round])
  end

  @doc """
  Gets lap data for a specific year and round from the database.
  Returns nil if not found.
  """
  def get_by_year_and_round(year, round) do
    Repo.get_by(__MODULE__, year: year, round: round)
  end

  @doc """
  Stores lap data for a specific year and round in the database.
  """
  def store(year, round, data) do
    %__MODULE__{}
    |> changeset(%{year: year, round: round, data: data})
    |> Repo.insert(on_conflict: {:replace, [:data, :updated_at]}, conflict_target: [:year, :round])
  end
end
