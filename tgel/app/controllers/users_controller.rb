class UsersController < ApplicationController
#  require "tgel"
#  include TgelMethods
  def login
    user= TgelUser.find_by_login params[:login]
    if user
      session[:user_id]= user.id
      $user_id= user.id
      tgel_log "LOGIN", "user #{user.login}(#{user.id}) logged in"
    else
      tgel_log "SECURITY", "user #{params[:login]} log in failure"
      flash[:notice]= "รหัสไม่ถูกต้อง โปรดตรวจสอบ"
    end
    redirect_to_root
  end
  def logout
    user= TgelUser.find session[:user_id]
    tgel_log "LOGOUT", "user #{user.login}(#{user.id}) logged out"
    reset_session
    redirect_to_root
  end
end