class Admin::ProductsController < AdminController
  include AdminModelControllerMethods
  include VersionedModelControllerMethods
  include AutoComplete
  layout 'admin_products'

  auto_complete_for :bisac_subject, :literal, { :select => 'CONCAT(id, ": ", literal) as literal' }

  before_filter :load_product, :only => [:assign_link, :delete_link]
  
  def index
    if params[:q]
      params[:search] = {}
      if params[:q].match(/^978/)
        params[:q] = params[:q].gsub('-', '')
        params[:search][:product_formats_isbn_equals] = params[:q]
      else
        params[:search][:name_contains] = params[:q]
      end
    end
    @search = Product.search(params[:search])
    @products = @search.paginate(:page => params[:page], :per_page => pager)
  end
  
  def show
    redirect_to show_path(@product)
  end
  
  def import
    if request.post?
      file = (params[:import] ? params[:import][:uploaded_data] : nil) # ActionDispatch::Http::UploadedFile OR Rack::Test::UploadedFile (TEST)
      if file
        # attention! ActionDispatch::Http::UploadedFile and Rack::Test::UploadedFile are different classes!
        filepath = file.is_a?(ActionDispatch::Http::UploadedFile) ? file.tempfile.path : file.path
        mimetype = file.content_type.to_s.strip!
        begin
          mac = params[:import][:mac] == '1'
          if params[:import][:synchronous] == '1'
            ProductsParser.execute(filepath, :mac => mac)
            flash[:notice] = "CSV import successful."
          else
            tmpfile = "#{Rails.root.to_s}/tmp/products_import_#{File.basename(filepath)}_#{file.original_filename}"
            FileUtils.cp( filepath, tmpfile )
            if File.exist?(tmpfile)
              job =Delayed::Job.enqueue(ProductsParserJob.new(tmpfile, :mac => mac))
              if job
                flash[:notice] = "Your request has been <a href=\"#{admin_jobs_path}\">queued</a> as Job ##{job.id}.".html_safe
              else
                flash[:error] = "Error queuing import job. Contact #{CONFIG[:webmaster_email]}."
              end
            else
              flash[:error] = "Error processing uploaded file."
            end
          end
          redirect_to admin_products_url and return
        rescue Exception => e
          flash.now[:error] = "Import failed. Contact #{CONFIG[:webmaster_email]}."
        end
      else
        flash.now[:error] = "Please select a file."
      end
    end
  end
  
  def export
    @formats = Format.find_single_units
    if request.post?
      if !verify_date_params
        # Error message set by verify_date_params
      elsif !params[:data_format_ids] || !params[:data_format_ids].any?
        flash.now[:error] = "Please select at least one Product Format."
      elsif !params[:data_template] || !ProductsExporter::TEMPLATES.keys.include?(params[:data_template])
        flash.now[:error] = "Please select a template."
      else
        options = params.to_hash.symbolize_keys    # to avoid affecting sticky fields
        product_klass = Product::TYPES.keys.include?(options[:data_class]) ? options[:data_class].classify.constantize : Title
        products = product_klass.find_using_options(options)
        if file_path = ProductsExporter.execute(products, options)
          ext = File.extname(file_path).sub('.','')
          content_type = "text/#{ext}"
          send_file(file_path, :type => content_type, :x_sendfile => CONFIG[:use_xsendfile])
        else
          flash.now[:error] = "Failed to export data file."
        end
        # Http header sent with file, can't redirect or render
      end
    else
      # Defaults
      params[:data_template] = 'standard'
      params[:data_format_ids] = [Format::DEFAULT_ID.to_s]
      params[:data_class] = 'Title'
    end
  end

  def assign_link
    link = Link.find(params[:links_products][:link_id])
    respond_to do |format|
      if !@product.nil? && !link.nil? && @product.links << link
        format.js {
          render :update do |page|
            page.insert_html :bottom, 'link_assignments', {:partial => 'link_assignment_row', :locals => {:assignment => link}}
            page.visual_effect :highlight, dom_id(link)
            page[:link_assignment_form].reset
          end
        }
        format.html {
          flash[:notice] = 'Link was successfully assigned.'
          redirect_to edit_admin_product_url(@product)
        }
        format.xml  { head :ok }
      else
        msg = "The Link could not be assigned."
        format.js {
          render :update do |page|
            page.alert(msg)
          end
        }
        format.html {
          flash[:error] = msg
          redirect_to @product.nil? ? admin_products_url : edit_admin_product_url(@product)
        }
        format.xml  { render :xml => msg + (@product.nil? ? "" : @product.errors), :status => :unprocessable_entity }
      end
    end
  end


  def delete_link
    link = @product.links.find(params[:link_id]) unless @product.nil?
    respond_to do |format|
      if !@product.nil? && !link.nil? && @product.links.delete(link)
        format.js {
          render :update do |page|
            page.visual_effect(:fade, dom_id(link), :duration => CONFIG[:fade_duration])
            page[:link_assignment_form].reset
          end
        }
        format.html {
          flash[:notice] = 'Links assignment was successfully deleted.'
          redirect_to edit_admin_product_url(@product)
        }
        format.xml  { head :ok }
      else
        msg = 'Link assignment was NOT deleted.'
        format.js {
          render :update do |page|
            page.alert(msg)
          end
        }
        format.html {
          flash[:error] = msg
          redirect_to @product.nil? ? admin_products_url : edit_admin_product_url(@product)
        }
        format.xml  { render :xml => msg + (@product.nil? ? "" : @product.errors), :status => :unprocessable_entity }
      end
    end
  end

  def select
    respond_to do |format|
      format.js {
        render :update do |page|
          page.visual_effect :fade, :product_select_partial, :duration => CONFIG[:fade_duration]
          page.delay(CONFIG[:fade_duration]*2) do
            if Product::SELECT_PARTIALS.include?(params[:product_select])
              page.replace_html :product_select_partial, :partial => "admin/products/#{params[:product_select]}"
            else
              page.replace_html :product_select_partial, nil
            end
            page.visual_effect :appear, :product_select_partial, :duration => CONFIG[:fade_duration]
          end
        end
      }
      format.html {
        redirect_to admin_distribution_url(:product_select => params[:product_select])
      }
    end
  end
  
  protected

    def load_product
      @product = Product.find(params[:id])
    rescue Exception => e
      flash[:error] = "Error finding Product #{params[:id]}: #{e.message}"
    end
end
