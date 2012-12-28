class ShopController < ApplicationController
  skip_before_filter :login_required, :except => [:email]
  before_filter :init_cart
  before_filter :clean_cart, :only => [:cart]
  before_filter :store_location, :only => [:index, :show, :cart, :quick, :new_titles, :new_arrivals, :recent_arrivals]
  after_filter :update_history, :only => [:show]
  after_filter :set_cart_cookie, :only => [ :add, :update, :add_by_isbn ]
  
  { :add => :items, 
    :add_by_isbn => :isbn, 
    :update => :items}.each do |action, param|
    verify :only => action, :params => param, :method => :post, 
      :redirect_to => { :action => 'index' }
  end
  
  def index
    @new_titles = Title.find_random_new(3)
  end
  
  def cart
    @page_title = "Shopping Cart"
    render :layout => 'checkout'
  end
  
  def advanced_search
    @page_title = "Advanced Search"
  end
  
  def search_results
    if params[:available_on].is_a?(String) && !params[:available_on].blank? && !/^\d{4}-\d{1,2}-\d{1,2}$/.match(params[:available_on])
      if match = /^(\d{1,2}).(\d{1,2}).(\d{2})$/.match(params[:available_on])
        year = match[3].to_i
        year += (year > Date.today.year.to_s.slice(2,2).to_i + 1 ? 1900 : 2000)
        params[:available_on] = "#{year}-#{sprintf("%02d", match[1].to_i)}-#{sprintf("%02d", match[2].to_i)}"
      elsif match = /^(\d{1,2}).(\d{1,2}).(\d{4})$/.match(params[:available_on])
        params[:available_on] = "#{match[3]}-#{sprintf("%02d", match[1].to_i)}-#{sprintf("%02d", match[2].to_i)}"
      else
        flash.now[:error] = "Date available must by formatted as 'YYYY-MM-DD'"
        render :action => 'advanced_search' and return false
      end
    end
    search_pairs = Product.process_search_params(params)
    flash.now[:error] = "Please define at least one filter" unless search_pairs.any?
    @form_values = params.reject {|k,v| !Product::SEARCHABLE_FIELDS.include?(k)}
    @partial = session[:layout] == 'x' ? 'xproducts' : 'products'
    if params[:commit] == 'Export'
      @products = Product.advanced_search(search_pairs)
      unless @products.any?
        flash.now[:error] = "No records found."
      end
      unless file_path = ProductsExporter.execute(@products, :data_template => params[:data_template], :data_format_ids => params[:product_formats_format_id_equals], :status => params[:product_formats_status_in].try(:values))
        flash.now[:error] = "Failed to export data file."
      end
      unless flash.now[:error]
        ext = File.extname(file_path).sub('.','')
        content_type = "text/#{ext}"
        send_file(file_path, :type => content_type, :x_sendfile => CONFIG[:use_xsendfile])
        # Http header sent with file, can't redirect or render
      else
        render :action => 'advanced_search'
      end
    else
      @products = Product.advanced_search(search_pairs, :page => params[:page], :per_page => pager)
      respond_to do |format|
        format.html {
          unless @products.any?
            flash.now[:error] = "No records found."
          end
          unless flash.now[:error]
            render :layout => (CONFIG[:show_search_filters] ? 'search' : 'shop')
          else
            render :action => 'advanced_search'
          end
        }
        format.xml { render :xml => @products.to_xml }
        format.js  {
          if flash.now[:error]
            render :search_results_error
          end
        }
      end
    end
  end
  
  def export
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename=products.csv'
    @products = Product.available.order( "collection_id, name")
    render :action => 'export', :layout => false
  end
  
  def export_cart
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename=cart.csv'
    render :action => 'export_cart', :layout => false
  end
  
  def quick
    @page_title = "QuickShop"
    if !params[:assembly].blank?
      @assembly = Assembly.available.active.find(params[:assembly])
      @products = @assembly.try(:titles)
    elsif !params[:q].blank?
      search_pairs = Product.process_search_params(params)
      @products = Product.advanced_search(search_pairs, :page => params[:page], :per_page => pager).active
      if @products.size == 1
        product = @products.first
        if product.is_a?(Assembly)
          @assembly = product
        else
          @assembly = product.assemblies.available.last
        end
        @products = @assembly.try(:titles) if @assembly
      end
    else
      @products = Assembly.join_formats_with_distinct.available.active.except(:order).order(:name)
    end
    render :layout => 'quick'
  end
  
  def show
    redirect_to shop_url and return if params[:id].blank?
    @product = Product.find(params[:id])
    render_show
  end
  
  def isbn
    if @product = Product.find_by_isbn(params[:isbn].gsub('-',''))
      render_show
    else
      flash[:error] = "No product found matching ISBN '#{params[:isbn]}'."
      redirect_to root_url
    end
  end
  
  def pid
    if @product = Product.find_by_proprietary_id(params[:pid])
      render_show
    else
      flash[:error] = "No product found matching PID '#{params[:pid]}'."
      redirect_to root_url
    end
  end
  
  def add
    items = []
    # data is a hash with keys: id, quantity
    params[:items].values.each do |data|
      ids = data[:id].is_a?(Array) ? data[:id] : Array(data[:id])
      ids.each do |id|
        items << {:item => ProductFormat.active.find(id), :quantity => data[:quantity]}
      end
    end
    add_items(items)
  end
  
  def add_by_isbn
    items = params[:isbn].gsub('-','').split(/,?\s+/).inject([]) {|sum, isbn| sum + [{:item => ProductFormat.active.find_by_isbn(isbn.strip), :quantity => 1}]}
    add_items(items)
  end
  
  def add_one
    if product_format = ProductFormat.where("product_formats.id = ? AND product_formats.status = ? AND products.available_on <= NOW()", params[:id], ProductFormat::ACTIVE_STATUS_CODE).includes(:product).first
      @cart.add_item(product_format)
      @cart.update_amount!
      show_cart(:notice, "#{product_format.product.name} has been added to your cart.")
    else
      show_cart(:error, "A product with the ID '#{params[:id]}' could not be found.")
    end
  end
  
  def update
    params[:items].each do |item_id, data|
      # data is a hash with keys: id, quantity
      @cart.update_item(item_id, data[:quantity], data[:id])
    end
    @cart.merge_line_items
    show_cart(:notice, "Your cart has been updated.")
  end
  
  def new_titles
    @products = Title.grade(params[:grade]).newly_available.order(:name).paginate(:page => params[:page], :per_page => pager)
  end
  
  def new_arrivals
    load_arrivals(:season => 'new')
  end
  
  def recent_arrivals
    load_arrivals(:season => 'recent')
  end
  
  def history
    @products = session[:history]
  end
  
  def enlarge
    params[:type] = "covers" if params[:type].blank?
    @product = Product.find(params[:id])
    respond_to do |format|
      format.html { render :layout => 'blank' }
      format.js   {
        render :update do |page|
          # IE7 issue: couldn't center modal in browser window
          # created kludge to calculate center based on browser width and image width
          file = Rails.root.join('public','images',@product.image(params[:type],'l'))
          width = ( File.exist?(file) && img = Magick::Image::read(file) ) ? img.first.columns : 0
          page << "function centerElement(element) {return (document.viewport.getScrollOffsets()[0]+document.viewport.getWidth()-#{width})/2+'px';}"
          page << "$('modal').setStyle({'left': centerElement('modal')})"
          page[:modal].replace_html :partial => "enlarge", :locals => { :product => @product }
          page.draggable(:modal, {:revert => false})
          page.visual_effect(:appear, :modal, {:queue => 'front', :duration => 0.7})
          page.visual_effect(:appear, :screen, {:to => 0.5, :queue => 'front', :duration => CONFIG[:fade_duration]})
        end
      }
    end
  end
  
  def email
    @product = Product.find_by_id(params[:id])
    if @product.nil?
      flash[:notice] = 'Product unknown.'
      redirect_to root_path and return
    end
    @page_title = "Tell a Friend - #{@product.name}"
    if request.post?
      @form = Email.new(params[:form])
      if @form.valid?
        NotificationMailer.product(@form, current_user, @product).deliver
        flash[:notice] = "Your message was successfully delivered."
        redirect_to show_path(@product)
      end
    else
      @form = Email.new
    end
  end
  
  def buy_now
    @item = @cart.saved_items.find(params[:id])
    if @item.product_format.active?
      @item.update_attribute(:saved_for_later, nil)
      @cart.update_amount!
      render :update do |page|
        page.insert_html :bottom, 'current_item_list', :partial => 'item', :object => @item
        page.replace_html 'cart_amount', number_to_currency(@cart.amount)
        page.remove "saved_line_item_#{@item.id}"
        page.show 'no_saved_items_row' if @cart.saved_items.empty?
        page.call 'stripeTables'
      end
    else
      render :update do |page|
        page.insert_html :top, :content, :partial => 'shared/status_error', :locals => {:product_format => @item.product_format}
        page.delay(3) do
          page.visual_effect(:fade, :flash_error, {:duration => CONFIG[:fade_duration]})
        end
      end
    end
  end
  
  def buy_later
    @item = @cart.line_items.find(params[:id])
    @item.update_attribute(:saved_for_later, true)
    @cart.update_amount!
    render :update do |page|
      page.insert_html :bottom, 'saved_item_list', :partial => 'item', :object => @item
      page.replace_html 'cart_amount', number_to_currency(@cart.amount)
      page.remove "current_line_item_#{@item.id}"
      page.hide 'no_saved_items_row'
      page.call 'stripeTables'
    end
  end
  
  def remove_item
    @item = @cart.update_item(params[:id], 0)
    render :update do |page|
      page.replace_html 'cart_amount', number_to_currency(@cart.amount)
      page.remove "saved_line_item_#{@item.id}"
      page.show 'no_saved_items_row' if @cart.saved_items.empty?
      page.call 'stripeTables'
    end
  end
  
  def destroy_cart
    # line_items does not include those that are saved_for_later
    @cart.line_items.clear
    @cart.update_amount!
    show_cart
  end
  
  def coupon
    if discount = Discount.find_by_code(params[:discount_code])
      if discount.available?
        @cart.update_attribute(:discount_code, discount.code)
        flash[:notice] = 'Your coupon code has been applied!'
      else
        flash[:error] = "Sorry, the coupon code has expired or is not yet available."
      end
    else
      flash[:error] = "Sorry, the coupon code '#{params[:discount_code]}' is invalid."
    end
    redirect_to cart_path
  end
  
  protected
  
    def show_cart(message_type = nil, message = nil)
      respond_to do |format|
        format.html {
          flash[message_type] = message if message
          redirect_to cart_path
        }
        format.js {
          render :update do |page|
            page['top'].visual_effect :scroll_to
            page.replace 'cart_summary', :partial => 'cart_summary'
            page.replace 'quick_links', :partial => 'quick_links'
            options = {:duration => 5}
            options[:startcolor] = CONFIG[:cart_startcolor] unless CONFIG[:cart_startcolor].blank?
            options[:endcolor] = CONFIG[:cart_endcolor] unless CONFIG[:cart_endcolor].blank?
            page.visual_effect :highlight, 'cart_summary', options
            page[:products_form].reset
          end
        }
      end
    end
    
    def add_items(items)
      items.delete_if { |item| item[:quantity] == '' }
      i = 0 # count items added
      items.each do |data|
        i += 1 if @cart.add_item(data[:item], data[:quantity])
      end
      @cart.update_amount!
      if i > 0
        if i == items.size
          show_cart(:notice, "The selected items have been added to your cart.")
        else
          show_cart(:notice, "Some of selected items have been added to your cart, some were unavailable.")
        end
      else
        flash[:error] = "No items added to your cart."
        redirect_to(:back) and return
      end
    end
    
  private

    def update_history
      session[:history] ||= []
      unless @product.nil?
        session[:history].delete(@product.id)
        session[:history] = session[:history][0..8].unshift(@product.id)
      end
    end
    
    def render_show
      begin
        raise "Format not available!" unless @product.default_format
        @page_title = @product.name
        if !@product.available?
          if admin?
            flash.now[:notice] = "Available on #{@product.available_on}."
          else
            flash[:error] = "Product not yet available."
            redirect_to root_url and return
          end
        end
      rescue ActiveRecord::RecordNotFound
        raise ProductNotFound
      rescue Exception => e
        flash[:error] = 'Error finding product'.concat(" (#{e.message})")
        redirect_back_or_default(root_url)
        return
      end
      respond_to do |format|
        format.html { render :show }
        format.js   {
          render :update do |page|
            page[:view].replace_html :partial => 'shared/view2', :locals => {:remote => true}
            if session[:layout2] == 's' && @product.respond_to?(:titles)
              page[:subproducts].replace_html :partial => 'shop/products', :locals => { :products => @product.titles.available, :assembly => @product }
            else
              page[:subproducts].replace_html :partial => 'shop/productsx', :locals => { :product => @product }
            end
          end
        }
      end
    end

    def load_arrivals(options = {})
      season = %w(new recent).include?(options[:season]) ? options[:season] : 'new'
      # TODO: Fix this very ugly, time-consuming calculation for @assemblies
      assemblies = Assembly.grade(params[:grade]).send("#{season}ly_available").spotlighted.order(:name)
      @assemblies = assemblies.delete_if { |assembly| !assembly.collection || !Collection.find_by_name(assembly.name).try(:children).try(:empty?) }.compact
    end

end
