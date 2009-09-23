require 'test_helper'

class TgelLogsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tgel_logs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tgel_log" do
    assert_difference('TgelLog.count') do
      post :create, :tgel_log => { }
    end

    assert_redirected_to tgel_log_path(assigns(:tgel_log))
  end

  test "should show tgel_log" do
    get :show, :id => tgel_logs(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => tgel_logs(:one).to_param
    assert_response :success
  end

  test "should update tgel_log" do
    put :update, :id => tgel_logs(:one).to_param, :tgel_log => { }
    assert_redirected_to tgel_log_path(assigns(:tgel_log))
  end

  test "should destroy tgel_log" do
    assert_difference('TgelLog.count', -1) do
      delete :destroy, :id => tgel_logs(:one).to_param
    end

    assert_redirected_to tgel_logs_path
  end
end
