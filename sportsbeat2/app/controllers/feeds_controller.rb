require 'canner'

class FeedsController < ApplicationController
  include Roar::Rails::ControllerAdditions
  before_filter :authenticate_user!
  respond_to :json

  def show
    if params[:older_than]
      begin
        DateTime.parse params[:older_than]
      rescue
        not_found
        return
      end
    end

    owner_type = params[:owner_type].to_s
    owner_id = params[:owner_id].to_s
    owner_class = owner_type.camelize.classify.constantize
    owner = owner_class.find owner_id
    owner_key = owner_type + ":" + owner_id

    name = params[:name]
    options = {
      :newer_than => params[:newer_than],
      :older_than => params[:older_than]
    }
    entries = FeedEntry.entries_for(owner_key, name, options).limit(10)
    self_url = feed_url owner_type, owner_id, name, options

    if entries.first
      newer_url = feed_url owner_type, owner_id, name, {:newer_than => entries.first.iso8601}
    else
      newer_url = nil
    end

    if entries.last
      older_url = feed_url owner_type, owner_id, name, {:older_than => entries.last.iso8601}
    else
      older_url = nil
    end

    o = {
      :name => name,
      :owner => owner,
      :entries => entries,
      :self_url => self_url,
      :newer_url => newer_url,
      :older_url => older_url,
    }

    respond_with Canner.new(o, current_ability), :represent_with => FeedRepresenter
  end
end
