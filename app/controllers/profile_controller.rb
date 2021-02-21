class ProfileController < ApplicationController
  before_action :set_user, only: [:wall, :about, :friends, :friend_request, :un_friend, :pictures, :debate_tokens, :question_tokens, :note_tokens, :tracking, :feed]
  before_action :friend_count, only: [:wall, :about, :friends, :friend_request, :pictures, :debate_tokens, :question_tokens, :note_tokens, :tracking, :feed]
  before_action :connection_requests_count, only: [:wall, :about, :friends, :friend_request, :pictures, :debate_tokens, :question_tokens, :note_tokens, :tracking, :feed]

  def wall
    @posted_posts = @user.posts.posts_feed
    @liked_posts = @user.likes.where(likeable_type: 'Post').collect(&:likeable)
    @commented_posts = @user.comments.collect(&:commentable)
    @flagged_posts = @user.flags.where(flagable_type: 'Flag').collect(&:flagable)
    @shared_posts = @user.shares.collect(&:shareable)
  end

  def about; end

  def friends
    @f = User.ransack(params[:q])
    @friends = Kaminari.paginate_array(@user.links).page(params[:page]).per(12)
  end

  def friend_request
    @connection_requests = ConnectionRequest.where(to: @user.uuid, status: 'pending').page(params[:page]).per(12)
  end

  def un_friend
    links = current_user.links
    if @user && links.include?(@user)
      connections = Connection.where(user_id: @user.id, friend_id: current_user.id).or(Connection.where(user_id: current_user, friend_id: @user.id))
      if connections.present? && connections.destroy_all
        flash[:notice] = "You and #{@user.name} are no longer friends"
      else
        flash[:alert] = 'Sorry, your request was not successful. Please try later.'
      end
    else
      flash[:alert] = "You are not friends with #{@user.name}, you can not unfriend this user"
    end
    redirect = params[:redirect]
    redirect_to_uuid = redirect == 'current' ? current_user.uuid : @user.uuid
    redirect_to wall_path(uuid: redirect_to_uuid)
  end

  def pictures; end

  def modal_picture
    @picture = current_user.pictures.find_by_id(params[:id])
  end

  def my_connections
    @keywords = params[:first_name]
    @f = User.ransack(first_name: @keywords)
    @friends = @f.result.order("random()").page(params[:page]).per(12)
  end

  def search_results
    @f = User.ransack(params[:q])
    @friends = @f.result.page(params[:page]).per(12)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def add_details
    @user = current_user
  end

  def profile_image; end

  def tracking
    @tracking_posts = @user.tracking_posts
  end

  def debate_tokens
    @debate_tokens = Post.where(id: @user.post_tokens.debate_tokens.pluck(:post_id))
  end

  def question_tokens
    @question_tokens = Post.where(id: @user.post_tokens.question_tokens.pluck(:post_id))
  end

  def note_tokens
    @note_tokens = Post.where(id: @user.post_tokens.note_tokens.pluck(:post_id))
  end


  def update_profile_image

    if current_user.update(user_params)
      flash[:notice] = 'Your profile image has been changed'
    else
      flash[:alert] = @user.errors.full_messages.join(',')
    end
    redirect_to wall_path
  end

  def add_pictures
    @profile_change = params[:profile_change]
    @user = current_user
  end

  def update_details
    @user = User.find(params[:user][:user_id])

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to about_path, notice: 'Your details have been successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        flash[:alert] = @user.errors.full_messages.join(',')
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_pictures
    @user = User.find(params[:user][:user_id])

    respond_to do |format|
      if @user.present?
        if params[:user][:pictures].present?
          params[:user][:pictures].each do |image|
            @user.pictures.attach(image)
          end
        end
        format.html {redirect_to pictures_path, notice: 'Aad detail was successfully updated.'}
        format.json {render :show, status: :ok, location: @user}
      else
        flash[:alert] = @user.errors.full_messages.join(',')
        format.html {render :edit}
        format.json {render json: @user.errors, status: :unprocessable_entity}
      end
    end
  end

  def feed
    if @uuid
      activities = PublicActivity::Activity.where(owner_id: @user.id).order('created_at DESC').limit(50)
      posts = activities.select { |p| p.trackable_type == 'Post'}.map(&:trackable_id).uniq
      private_post_ids = Post.includes(:private_users).where(id: posts, private: true).reject{ |p| p.private_users&.include?(current_user) }&.pluck(:id)
      @activities = activities.reject { |p| private_post_ids.include?(p.trackable_id) }
    else
      @activities = PublicActivity::Activity.order('created_at DESC').limit(50)
      @activities = @activities.select { |p| p.trackable&.private == false }
    end
  end

  def get_users
    term = params[:term]
    if !term.is_a?(String) || term.blank?
      return []
    end

    @users = User.where.not(id: params[:excluded_ids]).where('first_name ILIKE ? OR last_name ILIKE ?', "#{term}%", "#{term}%").map{|item| {:id=>item.id,:text => item.name, profile_picture: item.profile_image.attached? ? url_for(item.profile_image) : ActionController::Base.helpers.asset_path('profile.png')}}
    respond_to do |format|
      format.json { render json: @users }
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:location, :about, :profile_image, pictures: [])
  end

  def set_user
    if params[:uuid].present?
      @user = User.find_by(uuid: params[:uuid])
      @uuid = params[:uuid]
    else
      @user = current_user
    end
  end

  def friend_count
    @friends_count = Kaminari.paginate_array(@user.links)
  end

  def connection_requests_count
    @connection_requests_count = ConnectionRequest.where(to: @user.uuid, status: 'pending')
  end

end
