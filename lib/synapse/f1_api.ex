defmodule Synapse.F1Api do
  @moduledoc """
  A utility module for fetching Formula 1 race results from the Ergast API.
  """

  alias Synapse.Admin.Truth
  alias Synapse.Admin.Event
  alias Synapse.Admin.Season
  alias Synapse.Repo
  alias Ecto.Multi

  @doc """
  Fetches all lap data for a specific year and round, handling pagination.

  ## Parameters
    - year: The year of the race (e.g., "2025")
    - round: The round number of the race (e.g., "1")

  ## Returns
    - {:ok, lap_data} - A map containing all lap data
    - {:error, reason} - If an error occurs during the request or parsing
  """
  def get_lap_data(year, round) do
    fetch_all_pages("https://api.jolpi.ca/ergast/f1/#{year}/#{round}/laps/", [])
  end

  @doc """
  Calculates the gap in seconds to the leader for each driver at each lap.

  ## Parameters
    - lap_data: The lap data returned by get_lap_data/2

  ## Returns
    - A map with lap numbers as keys and a list of driver gaps as values
  """
  def calculate_gaps_to_leader(lap_data) do
    case lap_data do
      {:ok, data} ->
        laps = get_in(data, ["MRData", "RaceTable", "Races", Access.at(0), "Laps"])

        Enum.reduce(laps, %{}, fn lap, acc ->
          lap_number = String.to_integer(lap["number"])
          timings = lap["Timings"]

          # Convert lap times to seconds
          driver_times = Enum.map(timings, fn timing ->
            driver_id = timing["driverId"]
            time_str = timing["time"]
            seconds = convert_time_to_seconds(time_str)

            %{
              driver_id: driver_id,
              position: String.to_integer(timing["position"]),
              time: seconds
            }
          end)

          # Find the leader's time
          leader = Enum.find(driver_times, fn timing -> timing.position == 1 end)

          # Skip laps where we can't find a leader (position 1)
          if leader do
            leader_time = leader.time

            # Calculate gaps
            driver_gaps = Enum.map(driver_times, fn timing ->
              gap = timing.time - leader_time

              %{
                driver_id: timing.driver_id,
                position: timing.position,
                gap: gap
              }
            end)

            Map.put(acc, lap_number, driver_gaps)
          else
            # Skip this lap if no leader is found
            acc
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp convert_time_to_seconds(time_str) do
    parts = String.split(time_str, ":")

    case length(parts) do
      1 ->
        # Just seconds
        String.to_float(time_str)
      2 ->
        # Minutes and seconds
        [minutes, seconds] = parts
        String.to_integer(minutes) * 60 + String.to_float(seconds)
      3 ->
        # Hours, minutes, and seconds
        [hours, minutes, seconds] = parts
        String.to_integer(hours) * 3600 + String.to_integer(minutes) * 60 + String.to_float(seconds)
    end
  end

  defp fetch_all_pages(url, accumulated_data) do
    case make_request(url) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, data} ->
            # Extract pagination info
            limit = String.to_integer(data["MRData"]["limit"])
            offset = String.to_integer(data["MRData"]["offset"])
            total = String.to_integer(data["MRData"]["total"])

            # Extract lap data
            laps = get_in(data, ["MRData", "RaceTable", "Races", Access.at(0), "Laps"])

            # Merge with accumulated data
            merged_data =
              if accumulated_data == [] do
                data
              else
                # Merge the laps data
                existing_laps = get_in(accumulated_data, ["MRData", "RaceTable", "Races", Access.at(0), "Laps"])

                # Create a map of existing laps by lap number for quick lookup
                existing_laps_map = Enum.reduce(existing_laps, %{}, fn lap, acc ->
                  Map.put(acc, lap["number"], lap)
                end)

                # Process new laps, updating existing ones if the lap number already exists
                updated_laps = Enum.reduce(laps, existing_laps, fn new_lap, acc ->
                  lap_number = new_lap["number"]

                  case Map.get(existing_laps_map, lap_number) do
                    nil ->
                      # Lap doesn't exist yet, add it to the list
                      acc ++ [new_lap]
                    existing_lap ->
                      # Lap exists, update the Timings
                      # Find the index of the existing lap to update it in the accumulator
                      index = Enum.find_index(acc, fn lap -> lap["number"] == lap_number end)
                      existing_timings = existing_lap["Timings"]
                      new_timings = new_lap["Timings"]

                      # Merge timings, updating existing ones if driver already exists
                      updated_timings = Enum.reduce(new_timings, existing_timings, fn new_timing, timings_acc ->
                        driver_id = new_timing["driverId"]

                        case Enum.find_index(timings_acc, fn timing -> timing["driverId"] == driver_id end) do
                          nil ->
                            # Driver doesn't exist in this lap yet, add timing
                            timings_acc ++ [new_timing]
                          timing_index ->
                            # Driver exists, update timing
                            List.replace_at(timings_acc, timing_index, new_timing)
                        end
                      end)

                      # Update the lap with merged timings
                      updated_lap = Map.put(existing_lap, "Timings", updated_timings)
                      List.replace_at(acc, index, updated_lap)
                  end
                end)

                updated_data = put_in(accumulated_data, ["MRData", "RaceTable", "Races", Access.at(0), "Laps"], updated_laps)
                updated_data
              end

            # Check if we need to fetch more pages
            if offset + limit < total do
              # Calculate next offset
              next_offset = offset + limit
              next_url = "#{url}?limit=#{limit}&offset=#{next_offset}"
              fetch_all_pages(next_url, merged_data)
            else
              {:ok, merged_data}
            end

          {:error, reason} ->
            {:error, "Failed to decode JSON: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def save_event(event_id, year, round) do
    {:ok, results} = get_race_results(year, round)

    multi =
      results
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {prediction, index}, multi ->
        changeset =
          %Truth{
            name: prediction,
            position: index + 1,
            event_id: event_id
          }
          |> Truth.changeset(%{})

        Multi.insert(
          multi,
          "truth_#{index}",
          changeset,
          on_conflict: {:replace, [:position]},
          conflict_target: [:event_id, :name]
        )
      end)

    case Repo.transaction(multi) do
      {:ok, _} ->
        :ok

      {:error, _, _changeset, _} ->
        :failed
    end
  end

  @doc """
  Fetches the first practice time for a specific year and round, and saves it as the event's deadline.

  ## Parameters
    - event_id: The ID of the event to update
    - year: The year of the race (e.g., "2025")
    - round: The round number of the race (e.g., "1")

  ## Returns
    - {:ok, datetime} - A DateTime struct representing the first practice time
    - {:error, reason} - If an error occurs during the request or parsing
  """
  def get_and_save_first_practice_time(event, year, round) do
    url = "https://api.jolpi.ca/ergast/f1/#{year}/#{round}/"

    case make_request(url) do
      {:ok, body} ->
        case parse_first_practice_time(body) do
          {:ok, datetime} ->
            # Update the event's deadline with the practice time
            Synapse.Admin.update_event(event, %{deadline: datetime})
            {:ok, datetime}

          error ->
            error
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def save_season_events_current_year() do
    year = Date.utc_today().year
    url = "https://api.jolpi.ca/ergast/f1/#{year}/"

    case make_request(url) do
      {:ok, body} ->
        parse_events(body)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_datetime_from_race_data(session_data) do
    case session_data do
      %{"date" => date, "time" => time} ->
        # Combine date and time into a single DateTime
        datetime_string = "#{date}T#{time}"

        {:ok, datetime, _offset} = DateTime.from_iso8601(datetime_string)
        datetime

      _ ->
        {:error, "FirstPractice data not found in response"}
    end
  end

  def parse_events(body) do
    season = Repo.get_by!(Season, name: Integer.to_string(Date.utc_today().year))

    case Jason.decode(body) do
      {:ok, data} ->
        try do
          multi =
            data
            |> get_in(["MRData", "RaceTable", "Races"])
            |> Enum.sort(&(String.to_integer(&1["round"]) < String.to_integer(&2["round"])))
            |> Enum.reduce(Multi.new(), fn race, multi ->
              changeset =
                %Event{
                  season_id: season.id,
                  name: race["raceName"],
                  deadline: get_datetime_from_race_data(race["FirstPractice"])
                }
                |> Event.changeset(%{})

              Multi.insert(
                multi,
                "event_#{race["round"]}",
                changeset,
                on_conflict: :nothing,
                conflict_target: [:season_id, :name]
              )
            end)

          case Repo.transaction(multi) do
            {:ok, results} ->
              Map.values(results) |> Enum.filter(fn event -> event.id != nil end)

            {:error, _, _changeset, _} ->
              :failed
          end
        rescue
          error -> {:error, "Failed to parse FirstPractice time: #{inspect(error)}"}
        end

      {:error, reason} ->
        {:error, "Failed to decode JSON: #{inspect(reason)}"}
    end
  end

  @doc """
  Fetches the race results for a specific year and round, returning a list of driver names
  in the order they finished.

  ## Parameters
    - year: The year of the race (e.g., "2025")
    - round: The round number of the race (e.g., "1")

  ## Returns
    - {:ok, [driver_names]} - A list of driver names in finishing order
    - {:error, reason} - If an error occurs during the request or parsing
  """
  def get_race_results(year, round) do
    url = "https://api.jolpi.ca/ergast/f1/#{year}/#{round}/results/"

    case make_request(url) do
      {:ok, body} -> parse_driver_names(body)
      {:error, reason} -> {:error, reason}
    end
  end

  defp make_request(url) do
    # Start Finch if it's not already started
    :ok = Application.ensure_started(:finch)

    case Finch.build(:get, url) |> Finch.request(Synapse.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Finch.Response{status: status}} ->
        {:error, "API request failed with status code: #{status}"}

      {:error, reason} ->
        {:error, "API request failed: #{inspect(reason)}"}
    end
  end

  defp parse_first_practice_time(body) do
    case Jason.decode(body) do
      {:ok, data} ->
        try do
          first_practice =
            data
            |> get_in(["MRData", "RaceTable", "Races"])
            |> List.first()
            |> Map.get("FirstPractice", %{})

          case first_practice do
            %{"date" => date, "time" => time} ->
              # Combine date and time into a single DateTime
              datetime_string = "#{date}T#{time}"

              case DateTime.from_iso8601(datetime_string) do
                {:ok, datetime, _offset} -> {:ok, datetime}
                {:error, reason} -> {:error, "Failed to parse datetime: #{reason}"}
              end

            _ ->
              {:error, "FirstPractice data not found in response"}
          end
        rescue
          error -> {:error, "Failed to parse FirstPractice time: #{inspect(error)}"}
        end

      {:error, reason} ->
        {:error, "Failed to decode JSON: #{inspect(reason)}"}
    end
  end

  defp parse_driver_names(body) do
    case Jason.decode(body) do
      {:ok, data} ->
        try do
          driver_names =
            data
            |> get_in(["MRData", "RaceTable", "Races"])
            |> List.first()
            |> Map.get("Results", [])
            |> Enum.sort_by(fn result -> String.to_integer(result["position"]) end)
            |> Enum.map(fn result ->
              driver = result["Driver"]

              "#{driver["givenName"] |> String.replace("Andrea Kimi", "Kimi") |> String.replace("Alexander", "Alex")} #{driver["familyName"]}"
            end)

          {:ok, driver_names}
        rescue
          error -> {:error, "Failed to parse driver names: #{inspect(error)}"}
        end

      {:error, reason} ->
        {:error, "Failed to decode JSON: #{inspect(reason)}"}
    end
  end
end
