require "test_helper"

class CategoryFormOptimizationTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.find_by!(email: "admin@admin.com")
  end

  test "page form loads category groups once across its fields" do
    queries = capture_sql_queries do
      get new_page_path
    end

    assert_response :success
    assert_includes response.body, "Status"
    assert_includes response.body, "Topics"
    assert_equal 1, category_group_queries(queries).size
  end

  private

  def capture_sql_queries
    queries = []
    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      sql = payload[:sql].to_s.squish
      next if payload[:cached]
      next if payload[:name].to_s == "SCHEMA"

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end

    queries
  end

  def category_group_queries(queries)
    queries.grep(/FROM "recording_studio_recordings".*recordable_type" = 'RecordingStudioCategorisable::CategoryGroup'/)
  end
end
