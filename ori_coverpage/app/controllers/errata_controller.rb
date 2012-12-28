class ErrataController < ApplicationController
  before_filter :login_required, :except => [:index]
  before_filter :load_product
  before_filter :init_cart
  before_filter :store_location, :only => [:index]

  def index
    @errata = @product.errata

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @errata }
    end
  end

  def show
    @erratum = Erratum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @erratum }
    end
  end

  def new
    @erratum = Erratum.new
    @erratum.user_id = @current_user.id
    @erratum.email = @current_user.email
    @erratum.name = @current_user.name
    @erratum.product_format_id = @product.default_format

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @erratum }
    end
  end

  def create
    @erratum = Erratum.new(params[:erratum])

    respond_to do |format|
      if @erratum.save
        flash[:notice] = 'Erratum was successfully created.'
        #format.html { redirect_to(@erratum) }
        format.html { redirect_to(product_errata_path(@product)) }
        format.xml  { render :xml => @erratum, :status => :created, :location => @erratum }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @erratum.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  private
  
  def load_product
    @product = Product.find(params[:product_id])
  end

end
