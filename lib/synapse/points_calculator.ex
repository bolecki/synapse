defmodule Synapse.Admin.PointsCalculator do
  import Ecto.Query
  alias Synapse.Repo
  alias Synapse.Admin.{RankedPrediction, Truth, Event}
  alias Synapse.Accounts.Profile

  # Alternative version that returns everything in a single query
  def calculate_points_single_query(user_id, event_id) do
    query =
      from rp in RankedPrediction,
        where: rp.user_id == ^user_id and rp.event_id == ^event_id,
        select: %{
          name: rp.name,
          position: rp.position,
          points:
            fragment(
              """
                CASE
                  -- Only consider predictions in top 11 positions
                  WHEN ? <= 11 THEN
                    CASE
                      -- Exact position match in top 11: position points + bonus point
                      WHEN EXISTS(
                        SELECT 1 FROM truths t
                        WHERE t.event_id = ? AND t.name = ? AND t.position = ? AND t.position <= 11
                      ) THEN ((12 - ?) + 1)
                      -- Name in top 11 but position doesn't match: 1 point
                      WHEN EXISTS(
                        SELECT 1 FROM truths t
                        WHERE t.event_id = ? AND t.name = ? AND t.position <= 11
                      ) THEN 1
                      -- Not in top 11: 0 points
                      ELSE 0
                    END
                  -- Predictions outside top 11 get 0 points
                  ELSE 0
                END
              """,
              rp.position,
              ^event_id,
              rp.name,
              rp.position,
              rp.position,
              ^event_id,
              rp.name
            ),
          total_points:
            fragment(
              """
                SUM(
                  CASE
                    -- Only consider predictions in top 11 positions
                    WHEN ? <= 11 THEN
                      CASE
                        -- Exact position match in top 11: position points + bonus point
                        WHEN EXISTS(
                          SELECT 1 FROM truths t
                          WHERE t.event_id = ? AND t.name = ? AND t.position = ? AND t.position <= 11
                        ) THEN ((12 - ?) + 1)
                        -- Name in top 11 but position doesn't match: 1 point
                        WHEN EXISTS(
                          SELECT 1 FROM truths t
                          WHERE t.event_id = ? AND t.name = ? AND t.position <= 11
                        ) THEN 1
                        -- Not in top 11: 0 points
                        ELSE 0
                      END
                    -- Predictions outside top 11 get 0 points
                    ELSE 0
                  END
                ) OVER ()
              """,
              rp.position,
              ^event_id,
              rp.name,
              rp.position,
              rp.position,
              ^event_id,
              rp.name
            )
        }

    # Execute the query
    results = Repo.all(query)

    # Extract the total points from the first result
    total_points =
      if Enum.empty?(results), do: 0, else: results |> List.first() |> Map.get(:total_points, 0)

    # Return the results
    %{
      driver_points:
        Enum.map(results, fn result -> Map.take(result, [:name, :position, :points]) end),
      total_points: total_points
    }
  end

  @doc """
  Calculates points for all users across all events in a given season.

  Returns a map where keys are user_ids and values are maps containing:
  - profile_name: The name of the user's profile
  - total_points: The sum of all points for that user across all events in the season
  - event_points: A map of event_id to points for that user
  """
  def calculate_season_points_by_user(season_id) do
    # First, get all events for this season
    events_query = from e in Event, where: e.season_id == ^season_id, select: e.id
    event_ids = Repo.all(events_query)

    # Query to calculate points for all users across all events in the season
    query =
      from rp in RankedPrediction,
        where: rp.event_id in ^event_ids,
        join: p in Profile,
        on: p.user_id == rp.user_id,
        select: %{
          user_id: rp.user_id,
          profile_name: p.name,
          event_id: rp.event_id,
          name: rp.name,
          position: rp.position,
          points:
            fragment(
              """
                CASE
                  -- Only consider predictions in top 11 positions
                  WHEN ? <= 11 THEN
                    CASE
                      -- Exact position match in top 11: position points + bonus point
                      WHEN EXISTS(
                        SELECT 1 FROM truths t
                        WHERE t.event_id = ? AND t.name = ? AND t.position = ? AND t.position <= 11
                      ) THEN ((12 - ?) + 1)
                      -- Name in top 11 but position doesn't match: 1 point
                      WHEN EXISTS(
                        SELECT 1 FROM truths t
                        WHERE t.event_id = ? AND t.name = ? AND t.position <= 11
                      ) THEN 1
                      -- Not in top 11: 0 points
                      ELSE 0
                    END
                  -- Predictions outside top 11 get 0 points
                  ELSE 0
                END
              """,
              rp.position,
              rp.event_id,
              rp.name,
              rp.position,
              rp.position,
              rp.event_id,
              rp.name
            )
        }

    # Execute the query
    results = Repo.all(query)

    # Group results by user_id
    results
    |> Enum.group_by(& &1.user_id)
    |> Enum.map(fn {user_id, user_predictions} ->
      # Get the profile name (should be the same for all predictions by this user)
      profile_name = user_predictions |> List.first() |> Map.get(:profile_name)

      # Group user's predictions by event_id
      event_points =
        user_predictions
        |> Enum.group_by(& &1.event_id)
        |> Enum.map(fn {event_id, event_predictions} ->
          # Calculate total points for this event
          event_total = Enum.sum(Enum.map(event_predictions, & &1.points))
          {event_id, event_total}
        end)
        |> Enum.into(%{})

      # Calculate total points across all events
      total_points = Enum.sum(Map.values(event_points))

      # Return user data
      %{profile_name: profile_name, total_points: total_points, event_points: event_points}
    end)
  end
end
