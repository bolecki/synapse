defmodule Synapse.AdminTest do
  use Synapse.DataCase

  alias Synapse.Admin

  describe "categories" do
    alias Synapse.Admin.Category

    import Synapse.AdminFixtures

    @invalid_attrs %{name: nil}

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Admin.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Admin.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Category{} = category} = Admin.create_category(valid_attrs)
      assert category.name == "some name"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Admin.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Category{} = category} = Admin.update_category(category, update_attrs)
      assert category.name == "some updated name"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Admin.update_category(category, @invalid_attrs)
      assert category == Admin.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Admin.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Admin.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Admin.change_category(category)
    end
  end

  describe "seasons" do
    alias Synapse.Admin.Season

    import Synapse.AdminFixtures

    @invalid_attrs %{name: nil}

    test "list_seasons/0 returns all seasons" do
      season = season_fixture()
      assert Admin.list_seasons() == [season]
    end

    test "get_season!/1 returns the season with given id" do
      season = season_fixture()
      assert Admin.get_season!(season.id) == season
    end

    test "create_season/1 with valid data creates a season" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Season{} = season} = Admin.create_season(valid_attrs)
      assert season.name == "some name"
    end

    test "create_season/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Admin.create_season(@invalid_attrs)
    end

    test "update_season/2 with valid data updates the season" do
      season = season_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Season{} = season} = Admin.update_season(season, update_attrs)
      assert season.name == "some updated name"
    end

    test "update_season/2 with invalid data returns error changeset" do
      season = season_fixture()
      assert {:error, %Ecto.Changeset{}} = Admin.update_season(season, @invalid_attrs)
      assert season == Admin.get_season!(season.id)
    end

    test "delete_season/1 deletes the season" do
      season = season_fixture()
      assert {:ok, %Season{}} = Admin.delete_season(season)
      assert_raise Ecto.NoResultsError, fn -> Admin.get_season!(season.id) end
    end

    test "change_season/1 returns a season changeset" do
      season = season_fixture()
      assert %Ecto.Changeset{} = Admin.change_season(season)
    end
  end

  describe "events" do
    alias Synapse.Admin.Event

    import Synapse.AdminFixtures

    @invalid_attrs %{name: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Admin.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Admin.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Event{} = event} = Admin.create_event(valid_attrs)
      assert event.name == "some name"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Admin.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Event{} = event} = Admin.update_event(event, update_attrs)
      assert event.name == "some updated name"
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Admin.update_event(event, @invalid_attrs)
      assert event == Admin.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Admin.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Admin.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Admin.change_event(event)
    end
  end
end
