require "test_helper"

class DashboardAccessTest < ActionDispatch::IntegrationTest
  test "returns success for authenticated user" do
    sign_in users(:one)

    get authenticated_root_path

    assert_response :success
  end

  test "returns home for unauthenticated user" do
    locale = I18n.locale

    get authenticated_root_path(locale:)

    assert_response :success
    assert_equal root_path(locale:), path
  end
end
