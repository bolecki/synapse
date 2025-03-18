defmodule Synapse.F1Api do
  @moduledoc """
  A utility module for fetching Formula 1 race results from the Ergast API.
  """

  alias Synapse.Admin.Truth
  alias Synapse.Repo
  alias Ecto.Multi

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

      {:error, _, changeset, _} ->
        :failed
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
