class UsersController < ApplicationController
#  require "tgel"
#  include TgelMethods
  def login
    user= TgelUser.authenticate params[:login], params[:password]
    if user
      session[:user_id]= user.id
      $user_id= user.id
      tgel_log "LOGIN", "user #{user.login}(#{user.id}) logged in"
    else
      tgel_log "SECURITY", "user #{params[:login]} log in failure"
      flash[:notice]= "รหัสไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง"
    end
    redirect_to_root
  end
  def logout
    user= TgelUser.find session[:user_id]
    tgel_log "LOGOUT", "user #{user.login}(#{user.id}) logged out"
    reset_session
    redirect_to_root
  end
  def new
    @user= TgelUser.new
  end
  def create
    @user= TgelUser.new params[:user]
    if @user.save
      flash[:notice]= "ขึ้นทะเบียนผู้ใช้เรียบร้อยแล้ว"
      redirect_to "/"
    else
      flash[:notice]= "ไม่สามารถขึ้นทะเบียนได้ กรุณาตรวจสอบอีกครั้ง"
      render :action=>:new
    end
  end
end