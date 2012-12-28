class Admin::CollectionsController < AdminController
  include AdminModelControllerMethods
  layout 'admin_collections'

  before_filter :load_collection, :only => [:assign_product, :delete_product]

  def assign_product
    product = Product.find(params[:product_id])
    if @collection && product
      respond_to do |format|
        if @collection.products << product
          format.js {
            render :update do |page|
              page.insert_html :bottom, 'assignments', {:partial => 'admin/shared/product', :locals => {:product => product, :assignable => @collection}}
              page.visual_effect :highlight, dom_id(product)
              page[:assignment_form].reset
            end
          }
          format.html {
            flash[:notice] = 'Product was successfully assigned.'
            redirect_to edit_admin_collection_url(@collection)
          }
          format.xml  { head :ok }
        else
          raise "An error has occurred."
        end
      end
    end
    
  rescue Exception => e
    msg = "The product could not be assigned - #{e.message}"
    respond_to do |format|
      format.js {
        render :update do |page|
          page.alert(msg)
        end
      }
      format.html {
        flash[:error] = msg
        redirect_to edit_admin_collection_url(@collection)
      }
      format.xml  { render :xml => @collection.errors, :status => :unprocessable_entity }
    end
  end

  def delete_product
    product = @collection.products.find(params[:product_id])
    if @collection && product
      respond_to do |format|
        if @collection.products.delete(product)
          format.js {
            render :update do |page|
              page.visual_effect(:fade, dom_id(product), :duration => CONFIG[:fade_duration])
              page[:assignment_form].reset
            end
          }
          format.html {
            flash[:notice] = 'Product assignment was successfully deleted.'
            redirect_to edit_admin_collection_url(@collection)
          }
          format.xml  { head :ok }
        else
          raise "An error has occurred."
        end
      end
    end

  rescue Exception => e
    msg = "Product assignment was NOT deleted - #{e.message}"
    respond_to do |format|
      format.js {
        render :update do |page|
          page.alert(msg)
        end
      }
      format.html {
        flash[:error] = msg
        redirect_to edit_admin_collection_url(@collection)
      }
    end
  end
  
  protected

    def load_collection
      @collection = Collection.find(params[:id])
    end
  
end
