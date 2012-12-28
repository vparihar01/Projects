class WishlistsController < ApplicationController
  before_filter :load_wishlist
  before_filter :init_cart

  def index
    @line_items = @wishlist.line_items.paginate( :page => params[:page], :per_page => pager )
  end

  def add
    j = 0 # items requested
    i = 0 # items added
    params[:wishlist_items].values.each do |data|
      # data is a hash with keys: id, quantity
      quantity = data["quantity"].to_i
      unless quantity.zero?
        ids = data[:id].is_a?(Array) ? data[:id] : Array(data[:id])
        ids.each do |id|
          j += 1
          i += 1 if @wishlist.add_item(ProductFormat.find(id), quantity)
        end
      end
    end
    if j == 0
      flash[:error] = "No items were selected to add to your wishlist."
      redirect_back_or_default(:action => :index) and return
    elsif i == j
      show_wishlist(:notice, "The selected items have been added to your wishlist.")
    elsif i > 0
      show_wishlist(:notice, "Some of selected items have been added to your wishlist, some were unavailable.")
    else
      flash[:error] = "No items added to your wishlist. Please try again."
      redirect_back_or_default(:action => :index) and return
    end
  end

  def update
    params[:items].each do |item_id, data|
      # data is a hash with keys: id, quantity
      @wishlist.update_item(item_id, data[:quantity], data[:id])
    end
    @wishlist.merge_line_items
    show_wishlist(:notice, "Your wishlist has been updated.")
  end
  
  def destroy
    @wishlist.destroy
    redirect_to wishlists_path
  end
  
  def load_cart
    flash[:error] = "Some items could not be placed in your cart because they are not available." unless @wishlist.copy_to_cart(@cart, params[:replace] == '1')
    redirect_to cart_path
  end
  
  protected
  
    def load_wishlist
      #@wishlist = Wishlist.find_or_create_by_user_id(current_user.id)
      @wishlist = Wishlist.find_by_user_id(current_user) || Wishlist.new(:user => current_user)
    end 

    def show_wishlist(message_type, message)
      if request.xhr?
        render :update_wishlist do |page|
          page.call 'showWishlistMessage', message_type.to_s, message
          page.replace_html 'wishlist_summary', :partial => 'wishlist_summary'
        end
      else
        flash[message_type] = message
        redirect_to :action => "index"
      end
    end    
    
end
