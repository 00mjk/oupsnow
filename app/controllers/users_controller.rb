class UsersController < ApplicationController

  before_filter :ensure_authenticated, :except => [:new, :create]
  before_filter :only_own_account, :only => [:edit, :update]

  ## TODO: put it on model
  #params_accessible :user => [:login, :firstname, :lastname, :email, :password, :password_confirmation]

  def new
    @user = User.new
    @title = "New user"
  end

  def edit
    @user = session.user
    @title = "edit my profile"
  end

  def create(user)
    @user = User.new(user)
    if @user.save
      flash[:notice] =  "User was successfully created"
      redirect_to edit_user_url(@user)
    else
      flash[:error] = "User failed to be created"
      render :new
    end
  end

  def update
    @user = User.first(:login => params[:login])
    return return_404 unless @user
    if @user.update_attributes(params[:user])
       redirect_to projects_url
    else
      render :edit
    end
  end

  def destroy
    @user = User.first(:login => params[:login])
    return return_404 unless @user
    if @user.destroy
      redirect_to users_url
    else
      raise InternalServerError
    end
  end

  private

  def only_own_account
    @user = User.first(:conditions => {:login => params[:login]})
    unless @user == session.user
      raise Unauthenticated
    end
  end

end # Users
