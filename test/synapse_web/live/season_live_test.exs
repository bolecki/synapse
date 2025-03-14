defmodule SynapseWeb.SeasonLiveTest do
  use SynapseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Synapse.AdminFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_season(_) do
    season = season_fixture()
    %{season: season}
  end

  describe "Index" do
    setup [:create_season]

    test "lists all seasons", %{conn: conn, season: season} do
      {:ok, _index_live, html} = live(conn, ~p"/seasons")

      assert html =~ "Listing Seasons"
      assert html =~ season.name
    end

    test "saves new season", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/seasons")

      assert index_live |> element("a", "New Season") |> render_click() =~
               "New Season"

      assert_patch(index_live, ~p"/seasons/new")

      assert index_live
             |> form("#season-form", season: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#season-form", season: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/seasons")

      html = render(index_live)
      assert html =~ "Season created successfully"
      assert html =~ "some name"
    end

    test "updates season in listing", %{conn: conn, season: season} do
      {:ok, index_live, _html} = live(conn, ~p"/seasons")

      assert index_live |> element("#seasons-#{season.id} a", "Edit") |> render_click() =~
               "Edit Season"

      assert_patch(index_live, ~p"/seasons/#{season}/edit")

      assert index_live
             |> form("#season-form", season: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#season-form", season: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/seasons")

      html = render(index_live)
      assert html =~ "Season updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes season in listing", %{conn: conn, season: season} do
      {:ok, index_live, _html} = live(conn, ~p"/seasons")

      assert index_live |> element("#seasons-#{season.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#seasons-#{season.id}")
    end
  end

  describe "Show" do
    setup [:create_season]

    test "displays season", %{conn: conn, season: season} do
      {:ok, _show_live, html} = live(conn, ~p"/seasons/#{season}")

      assert html =~ "Show Season"
      assert html =~ season.name
    end

    test "updates season within modal", %{conn: conn, season: season} do
      {:ok, show_live, _html} = live(conn, ~p"/seasons/#{season}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Season"

      assert_patch(show_live, ~p"/seasons/#{season}/show/edit")

      assert show_live
             |> form("#season-form", season: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#season-form", season: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/seasons/#{season}")

      html = render(show_live)
      assert html =~ "Season updated successfully"
      assert html =~ "some updated name"
    end
  end
end
