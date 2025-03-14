defmodule SynapseWeb.RankedPredictionLiveTest do
  use SynapseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Synapse.AdminFixtures

  @create_attrs %{name: "some name", position: 42}
  @update_attrs %{name: "some updated name", position: 43}
  @invalid_attrs %{name: nil, position: nil}

  defp create_ranked_prediction(_) do
    ranked_prediction = ranked_prediction_fixture()
    %{ranked_prediction: ranked_prediction}
  end

  describe "Index" do
    setup [:create_ranked_prediction]

    test "lists all ranked_predictions", %{conn: conn, ranked_prediction: ranked_prediction} do
      {:ok, _index_live, html} = live(conn, ~p"/ranked_predictions")

      assert html =~ "Listing Ranked predictions"
      assert html =~ ranked_prediction.name
    end

    test "saves new ranked_prediction", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/ranked_predictions")

      assert index_live |> element("a", "New Ranked prediction") |> render_click() =~
               "New Ranked prediction"

      assert_patch(index_live, ~p"/ranked_predictions/new")

      assert index_live
             |> form("#ranked_prediction-form", ranked_prediction: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#ranked_prediction-form", ranked_prediction: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/ranked_predictions")

      html = render(index_live)
      assert html =~ "Ranked prediction created successfully"
      assert html =~ "some name"
    end

    test "updates ranked_prediction in listing", %{
      conn: conn,
      ranked_prediction: ranked_prediction
    } do
      {:ok, index_live, _html} = live(conn, ~p"/ranked_predictions")

      assert index_live
             |> element("#ranked_predictions-#{ranked_prediction.id} a", "Edit")
             |> render_click() =~
               "Edit Ranked prediction"

      assert_patch(index_live, ~p"/ranked_predictions/#{ranked_prediction}/edit")

      assert index_live
             |> form("#ranked_prediction-form", ranked_prediction: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#ranked_prediction-form", ranked_prediction: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/ranked_predictions")

      html = render(index_live)
      assert html =~ "Ranked prediction updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes ranked_prediction in listing", %{
      conn: conn,
      ranked_prediction: ranked_prediction
    } do
      {:ok, index_live, _html} = live(conn, ~p"/ranked_predictions")

      assert index_live
             |> element("#ranked_predictions-#{ranked_prediction.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#ranked_predictions-#{ranked_prediction.id}")
    end
  end

  describe "Show" do
    setup [:create_ranked_prediction]

    test "displays ranked_prediction", %{conn: conn, ranked_prediction: ranked_prediction} do
      {:ok, _show_live, html} = live(conn, ~p"/ranked_predictions/#{ranked_prediction}")

      assert html =~ "Show Ranked prediction"
      assert html =~ ranked_prediction.name
    end

    test "updates ranked_prediction within modal", %{
      conn: conn,
      ranked_prediction: ranked_prediction
    } do
      {:ok, show_live, _html} = live(conn, ~p"/ranked_predictions/#{ranked_prediction}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Ranked prediction"

      assert_patch(show_live, ~p"/ranked_predictions/#{ranked_prediction}/show/edit")

      assert show_live
             |> form("#ranked_prediction-form", ranked_prediction: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#ranked_prediction-form", ranked_prediction: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/ranked_predictions/#{ranked_prediction}")

      html = render(show_live)
      assert html =~ "Ranked prediction updated successfully"
      assert html =~ "some updated name"
    end
  end
end
