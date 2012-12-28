class PostsController < ApplicationController
  before_filter :authenticate_user!

  def create
    subject_type = params[:subject_type]
    subject_id = params[:subject_id]
    subject_class = subject_type.camelize.classify.constantize
    subject = subject_class.find subject_id

    Post.transaction do
      p = Post.new
      p.actor = current_user
      p.subject = subject
      p.content = params[:text]
      p.save!
      p.push_to_feeds!
    end

    head :ok
  end

  def destroy
    post = Post.find params[:id]

    if can? :destroy, post
      post.destroy
    end

    head :ok
  end

  def show
  end
end
