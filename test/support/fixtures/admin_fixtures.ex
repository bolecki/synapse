defmodule Synapse.AdminFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Synapse.Admin` context.
  """

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Synapse.Admin.create_category()

    category
  end

  @doc """
  Generate a season.
  """
  def season_fixture(attrs \\ %{}) do
    {:ok, season} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Synapse.Admin.create_season()

    season
  end

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Synapse.Admin.create_event()

    event
  end
end
