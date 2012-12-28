class QuotesController < ApplicationController
  before_filter :load_quote, :except => [ :new, :create, :index ]
  before_filter :init_cart, :only => [ :index, :new, :create, :show, :load_cart ]

  def index
    @quotes = respective_quotes.order("line_item_collections.name ASC").paginate(:page => params[:page], :per_page => pager)
  end
  
  def new
    @quote = current_user.quotes.new
    @cart.line_items.each do |item|
      @quote.line_items << item.clone
    end
  end
  
  def show
    unless @quote.line_items.any?
      flash[:error] = "Quote ID ##{@quote.id} does not contain any line items."
      redirect_to quotes_url and return
    end
  end
  
  def create
    # make sure only admin can assign other user to quote (also protect against missing user_id)
    if !current_user.admin? || params[:quote][:user_id].nil?
      params[:quote][:user_id] = current_user.id
    end
    @quote = Quote.new(params[:quote])
    if @quote.save
      @quote.line_items.each do |li|
        price = li.product_format.price
        li.update_attributes(:unit_amount => price, :total_amount => price * li.quantity)
      end
      flash[:notice] = "The quote has been created."
      redirect_back_or_default quotes_url
    else
      render :action => 'new'
    end
  end
  
  def destroy
    if @quote.destroy
      flash[:notice] = "The quote has been deleted."
      redirect_to quotes_url
    else
      render :action => 'edit'
    end
  end
  
  def copy
    @new_quote = @quote.copy_to_quote
    redirect_to edit_quote_path(@new_quote)
  end
  
  def load_cart
    @quote.copy_to_cart(@cart, params[:replace] == '1')
    redirect_to cart_url
  end
  
  def export
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename=quote.csv'
    render :action => 'export', :layout => false
  end
  
  def update
    if @quote.update_attributes(params[:quote])
      @quote.merge_line_items
      flash[:notice] = "The #{@name.humanize.downcase} has been updated."
      redirect_back_or_default :action => 'show', :id => @quote
    else
      flash[:error] = "Failed to update #{@name.humanize.downcase}."
      render :action => 'edit'
    end
  end
  
  protected
  
    def load_quote
      @quote = respective_quotes.find(params[:id])
    end
    
    def respective_quotes
      if current_user.admin?
        Quote
      elsif current_user.head_sales_rep?
        current_user.sales_team.quotes
      else
        current_user.quotes
      end
    end
    
end
