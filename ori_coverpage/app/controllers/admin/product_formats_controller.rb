class Admin::ProductFormatsController < AdminController
  include VersionedModelControllerMethods
  before_filter :build_product_format, :only => [:new, :create]
  before_filter :load_product_format, :only => [:destroy, :update, :show, :edit]

  def show
    redirect_to edit_admin_product_url(@product_format.product)
  end

  def edit
    show
  end

  def create
    respond_to do |format|
      begin
        logger.debug("product format: #{@product_format}")
        if @product_format.save
          format.html { 
            flash[:notice] = 'Product format was successfully created.'
            redirect_to admin_product_url(@product_format.product)
          }
          format.js { 
            render :update do |page|
              page.insert_html :bottom, 'product_formats', {:partial => "admin/products/product_format_row", :locals => {:product_format => @product_format}}
              page.insert_html :bottom, 'product_formats', {:partial => "admin/products/product_format_edit", :locals => {:product_format => @product_format}}
              page[:product_format_form].reset
              page.visual_effect :highlight, dom_id(@product_format)
            end
          }
        else
          msg = "Record not saved: \n#{@product_format.errors.full_messages}"
          format.html { 
            flash[:notice] = msg
            redirect_to admin_product_url(@product_format.product)
          }
          format.js {
            render :update do |page|
               page.alert msg
            end
          }
        end
      rescue ActiveRecord::StatementInvalid => error
        if error.to_s =~ /Duplicate entry .* for key/
          msg = "Record not saved: Format already exists."
          format.html { 
            flash[:notice] = msg
            redirect_to admin_product_url(@product_format.product)
          }
          format.js { 
            render :update do |page|
              page.alert msg
            end
          }
        else
          msg = "Record not saved: Invalid data."
          format.js { 
            render :update do |page|
              page.alert msg
            end
          }
          raise error
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @product_format.update_attributes(params[:product_format])
        format.html { 
          flash[:notice] = 'Product format was successfully updated.'
          redirect_to admin_product_url(@product_format.product)
        }
        format.js {
          render :update do |page|
            page.visual_effect :blind_up, dom_id(@product_format, :edit), :duration => CONFIG[:blind_duration]
            page[dom_id(@product_format)].replace :partial => "admin/products/product_format_row", :locals => { :product_format => @product_format }
            page.visual_effect :highlight, dom_id(@product_format)
          end
        }
        format.xml  { head :ok }
      else
        msg = "Record not saved: \n#{@product_format.errors.full_messages}"
        format.html { 
          flash[:notice] = msg
          redirect_to admin_product_url(@product_format.product)
        }
        format.js {
          render :update do |page|
             page.alert msg
          end
        }
        format.xml  { render :xml => @product_format.errors.to_xml }
      end
    end
  end

  def destroy
    @product_format.destroy
    respond_to do |format|
      format.html { 
        flash[:notice] = 'Product format was deleted.'
        redirect_to admin_product_url(@product_format.product)
      }
      format.js { 
        render :update do |page|
          page.visual_effect :fade, dom_id(@product_format), :duration => CONFIG[:fade_duration]
          page.visual_effect :fade, dom_id(@product_format, :edit), :duration => CONFIG[:fade_duration]
        end
      }
    end
  end
  
  protected
    
    def build_product_format
      logger.debug("building product format")
      @product_format = ProductFormat.new(params[:product_format])
      logger.debug("BUILT product format")
    end
    
    def load_product_format
      @product_format = ProductFormat.find(params[:id])
    end
  
end
