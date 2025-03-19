defmodule Synapse.Admin.PointsCalculator do
  import Ecto.Query
  alias Synapse.Repo
  alias Synapse.Admin.{RankedPrediction, Truth}

  def calculate_points(user_id, event_id) do
    # Single query to calculate points for each driver and the total
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
            )
        }

    # Execute the query to get individual driver points
    driver_points = Repo.all(query)

    # Calculate total points
    total_points =
      Enum.reduce(driver_points, 0, fn %{points: points}, acc ->
        acc + if is_nil(points), do: 0, else: points
      end)

    %{
      driver_points: driver_points,
      total_points: total_points
    }
  end

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
end
