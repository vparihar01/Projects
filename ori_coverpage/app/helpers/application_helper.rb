# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # These instance variable (@page_*) are used by the meta-tags gem
  # See: display_meta_tags layouts
  def calculate_meta_tags
    # page title
    unless @page_title
      @page_title = case action_name
      when 'index'
        controller_name.titleize
      else
        action_name.humanize.titleize + ' - ' + controller_name.titleize
      end
    end

    # page description
    unless @page_description
      if @product
        @page_description = @product.description
      else
        @page_description = CONFIG[:meta_description]
      end
    end
    @page_description = truncate_to_nearest_word(@page_description, 200, "...")

    # page keywords
    @page_keywords ||= []
    unless @page_keywords.any?
      @page_keywords = CONFIG[:meta_keywords]
      if @product
        if @product.is_a?(Assembly)
          @page_keywords << @product.categories.map(&:name)
        else
          @page_keywords << @product.subjects
        end
        @page_keywords << @product.reading_level.to_s
      else
        @page_keywords << ["PreK-8", "leveled reading"]
      end
    end
    @page_keywords = @page_keywords.flatten.uniq
  end

  def calculate_admin_meta_tags
    # page title
    unless @page_title
      @page_title = case action_name
      when 'index'
        controller_name.titleize
      else
        action_name.humanize.titleize + ' - ' + controller_name.titleize
      end
    end

    # page description
    unless @page_description
      @page_description = nil
    end
    @page_description = truncate_to_nearest_word(@page_description, 200, "...")

    # page keywords
    @page_keywords ||= []
    unless @page_keywords.any?
      @page_keywords = []
    end
    @page_keywords = @page_keywords.flatten.uniq
  end

  def address_type_to_s(type)
    if type.to_s == 'bill_address'
      'billing'
    elsif type.to_s == 'ship_address'
      'shipping'
    else
      ''
    end
  end
  
  # For the h1 tag in an html.erb file
  def calculate_page_heading(heading = controller_name)
    case action_name
      when 'index'
        heading.titleize
      when 'show'
        heading.singularize.titleize
      when 'create'
        'New ' + heading.singularize.titleize
      when 'update'
        'Edit ' + heading.singularize.titleize
      else
        action_name.humanize.titleize + ' ' + heading.singularize.titleize
    end
  end
  
  def calculate_address_page_heading
    type = address_type_to_s(params[:address_type])
    case action_name
      when 'new'
        "New #{type.titleize} #{controller_name.singularize.titleize}"
      when 'create'
        "New #{type.titleize} #{controller_name.singularize.titleize}"
      when 'edit'
        "Edit #{type.titleize} #{controller_name.singularize.titleize}"
      when 'update'
        "Edit #{type.titleize} #{controller_name.singularize.titleize}"
      else
        calculate_page_heading
    end
  end
  
  def calculate_checkout_page_heading(text)
    "#{@step_heading} #{text}"
  end
  
  def submit_or_cancel(cancel_url = session[:return_to] ? session[:return_to] : (admin_scope? ? url_for(:action => 'index') : url_for(:action => 'index')), label = 'Save')
    page_buttons(submit_tag(label), link_to('Cancel', cancel_url))
  end
  
  def page_buttons(primary_button, secondary_button = nil)
    temp = ""
    unless secondary_button.nil?
      temp = content_tag(:span, secondary_button, :class => 'secondary')
    end
    content_tag(:div, raw(temp + primary_button), :class => 'pagebuttons')
  end

  def set_tab(file)
    @force_active ||= CONFIG[:layout_tabs][File.basename(file).sub(/\..*$/, '')]
  end

  def sticky_tab(label, *args, &block)
    options = args.extract_options!.symbolize_keys
    force_active = options[:force_active].nil? ? @force_active : options[:force_active] # controller variable is accessible
    has_submenu = options[:has_submenu].nil? ? true : options[:has_submenu] # default is true, otherwise use value
    css = [label]
    if has_submenu
      css << ["active", "hover"] if force_active == label
      content = link_to(label, '#')
    else
      css << ["active"] if force_active == label
      content = ""
    end
    content += with_output_buffer(&block)
    content_tag(:li, content.html_safe, :class => css.join(" "))
  end
  
  def drop_tab(item, *args, &block)
    options = args.extract_options!.symbolize_keys
    force_active = options[:force_active].nil? ? @force_active : options[:force_active] # controller variable is accessible
    has_submenu = options[:has_submenu].nil? ? true : options[:has_submenu] # default is true, otherwise use value
    force_active = force_active.to_s
    item = item.to_s
    is_active = force_active.blank? ? active_menu(item) : (item == force_active)
    css = [item]
    css << "active" if is_active
    css << "none" unless has_submenu
    content_tag(:li, :class => css.join(" "), &block)
  end
  
  def simple_tab(item, *args, &block)
    options = args.extract_options!.symbolize_keys
    force_active = options[:force_active].nil? ? @force_active : options[:force_active] # controller variable is accessible
    force_active = force_active.to_s
    item = item.to_s
    is_active = force_active.blank? ? active_menu(item) : (item == force_active)
    css = [item, "none"]
    css << "active" if is_active
    content_tag(:li, :class => css.join(" "), &block)
  end
  
  def truncate_to_nearest_word(text, length = 200, truncate_string = '&hellip;')
    return if text.nil?
    l = length - truncate_string.length
    if $KCODE == "NONE"
      truncated = text.length > length ? text[0...l] : text
    else
      chars = text.split(//)
      truncated = chars.length > length ? chars[0...l].join : text
    end
    truncated.gsub!(/\s+\w*$/, truncate_string) unless truncated == text
    truncated.html_safe
  end

  def discount_label(discount, label = ' off')
    (discount.percent? ? number_to_percentage(discount.amount * 100, :precision => 0) : number_to_currency(discount.amount)) + label
  end
  
  def product_format_tag(object, html_options={})
    alt_product_format_tag(object, true, html_options)
  end
  
  def product_format_tag_with_price(object, html_options={})
    alt_product_format_tag_with_price(object, true, html_options)
  end
  
  def alt_product_format_tag(object, show=true, html_options={})
    # pass this method a block to alter the label in the options tag
    # the variable iterated in the block is the ProductFormat record
    return unless product = get_product(object)
    html = ''
    name = "items[#{object.id}][id]"
    if CONFIG[:default_format_only] == true
      html += hidden_field_tag(name, product.default_format.id)
      if product.default_format.active?
        html += number_to_currency(product.default_price) if show
      else
        html += content_tag(:strike, number_to_currency(product.default_price), :class => 'subdue') if show
      end
    else
      if product.active_formats.any?
        selected = object.is_a?(LineItem) ? object.product_format_id : nil
        options = options_for_select(product.active_formats.where(:format_id => CONFIG[:show_format_ids]).collect {|f| [(block_given? ? (yield f) : f.to_s), f.id]}, selected)
      else
        options = options_for_select([["No active formats", ""]])
        html_options.merge!(:disabled => true)
      end
      html += select_tag(name, options, html_options)
    end
    html.html_safe
  end
  
  def alt_product_format_tag_with_price(object, show=true, html_options={})
    alt_product_format_tag(object, show, html_options) {|f| "#{f.to_s} (#{number_to_currency(f.price)})"}
  end

  def product_format_radio_button(f, selected, base_id, include_ajax = true, html_options = {}, &block)
    # pass this method a block to alter the label in the options tag
    # the variable iterated in the block is the ProductFormat record
    if include_ajax
      onchange = "if ($('wishlist_items_#{base_id}_id')) $('wishlist_items_#{base_id}_id').value = this.value;return false;"
      html_options.merge!(:onchange => onchange)
    end
    name = "items[#{base_id}][id]"
    price = number_to_currency(f.price)
    tag_label = (block_given? ? (yield f) : "#{f.to_s} (#{price})")
    unless f.active?
      html_options.merge!(:disabled => true)
      tag_label = content_tag(:strike, tag_label, :class => 'subdue')
    end
    content_tag(:div, radio_button_tag(name, f.id, selected, html_options) + label_tag("#{name}_#{f.id}", tag_label.html_safe), :class => "buy-row")
  end
  
  def product_format_check_box(f, selected, base_id, include_ajax = true, html_options = {}, &block)
    # pass this method a block to alter the label in the options tag
    # the variable iterated in the block is the ProductFormat record
    name = "items[#{base_id}][id][]"
    price = number_to_currency(f.price)
    tag_label = (block_given? ? (yield f) : "#{f.to_s} (#{price})")
    if f.active?
      id = "items_#{base_id}_id_#{f.id}"
      html_options.merge!(:id => id, :name => name)
      if logged_in? && include_ajax
        onchange = "if ($('items_#{base_id}_id_#{f.id}').checked) { if (!$('wishlist_items_#{base_id}')) $('wishlist_items_#{base_id}').insert({top: '#{hidden_field_tag "wishlist_#{name}", f.id, :id => "wishlist_#{id}"}'}) } else { if ($('wishlist_#{id}')) $('wishlist_#{id}').replace() };return false;"
        html_options.merge!(:onchange => onchange)
      end
    else
      html_options.merge!(:disabled => true)
      tag_label = content_tag(:strike, tag_label, :class => 'subdue')
    end
    content_tag(:div, check_box_tag(name, f.id, selected, html_options) + label_tag("#{name}#{f.id}", tag_label.html_safe), :class => "buy-row")
  end

  def get_product(object)
    if object.is_a?(Product)
      object
    elsif object.respond_to?(:product)
      object.product
    else
      nil
    end
  end

  def product_quantity_tag(object, value=nil, options={:size => "2"})
    return false unless product = get_product(object)
    if CONFIG[:default_format_only] == true
      if product.default_format.active?
        name = "items[#{object.id}][quantity]"
        text_field_tag name, value, options
      else
        content_tag(:span, product.default_format.status, :class => 'subdue')
      end
    else
      if product.active_formats.any?
        name = "items[#{object.id}][quantity]"
        text_field_tag name, value, options
      else
        content_tag(:span, "N/A", :class => 'subdue')
      end
    end
  end

  def cart_button(product, size = 's', options = {})
    buy_button(product, size, 'cart', options)
  end

  def wishlist_button(product, size = 's', options = {})
    buy_button(product, size, 'wishlist', options)
  end

  def buy_button(product, size = 's', type = 'cart', options = {})
    image_submit_tag("buttons/#{size}/add-#{type}.gif", options) if show_buy_button?(product)
  end

  def show_buy_button?(product)
    if CONFIG[:default_format_only] == true
      product.default_format.status == ProductFormat::ACTIVE_STATUS_CODE
    else
      product.active_formats.any?
    end
  end

  def product_status_tag(product)
    html = ''
    if CONFIG[:default_format_only] == true
      if product.default_format.status == ProductFormat::REPLACED_STATUS_CODE
        html += content_tag(:span, link_to("#{APP_STATUSES[product.default_format.status]['value']} &rarr;".html_safe, show_path(product.replacement)), :class => "inactive")
      elsif product.default_format.status != ProductFormat::ACTIVE_STATUS_CODE
        html += content_tag(:span, APP_STATUSES[product.default_format.status]['value'], :class => "inactive")
      end
    end
    html
  end

  def buy_form(product, options = {})
    return nil unless product.active_formats.any?
    # options: type, context, show_inactive_wishlist
    html = ''
    tags = ''
    acceptable_types = %w(check_box radio_button) # Default is first
    type = (acceptable_types.include?(options[:type]) ? options[:type] : acceptable_types.first)
    size = (options[:context] == 'list' ? 's' : 'l')
    qualifier = (size == 's' ? "-#{size}" : '')
    unless options[:context] == 'list' && !CONFIG[:show_buttons_in_list]
      selected = (CONFIG[:default_format_only] == true ? product.default_format : product.active_formats.first)
      cart_tags = hidden_field_tag("items[#{product.id}][quantity]", 1);
      if CONFIG[:default_format_only] == true
        cart_tags += hidden_field_tag("items[#{product.id}][id]", selected.id)
      else
        product.product_formats.where(:format_id => CONFIG[:show_format_ids]).each do |f|
          cart_tags += self.send("product_format_#{type}", f, (f.active? && f.id == selected.try(:id)), product.id, true)
        end
      end
      cart_tags += content_tag(:div, cart_button(product, size, :class => "submit#{qualifier}"), :class => "buttons");
      tags += form_tag(add_cart_path, :id => "items_#{product.id}") do
        cart_tags.html_safe
      end
      if logged_in?
        wish_tags = hidden_field_tag("wishlist_items[#{product.id}][quantity]", 1)
        name = "wishlist_items[#{product.id}][id]"
        wish_options = {}
        if CONFIG[:default_format_only] != true
          if type == 'check_box'
            name = "wishlist_items[#{product.id}][id][]"
            wish_options.merge!(:id => "wishlist_items_#{product.id}_id_#{selected.id}")
          end
        end
        wish_tags += hidden_field_tag(name, selected.id, wish_options)
        wish_tags += content_tag(:div, wishlist_button(product, size, :class => "submit#{qualifier}"), :class => "buttons")
        tags += form_tag(add_wishlists_path, :id => "wishlist_items_#{product.id}") do
          wish_tags.html_safe
        end
      else
        if options[:show_inactive_wishlist] && ((CONFIG[:default_format_only] == true && product.default_format.active?) || (CONFIG[:default_format_only] != true && product.active_formats.where(:format_id => CONFIG[:show_format_ids]).any?))
          tags += content_tag(:div, link_to(image_tag("buttons/#{size}/add-wishlist-off.gif", :alt => "You must login to add items to your wishlist"), login_path), :class => "buttons")
        end
      end
    end
    tags += product_status_tag(product)
    html += content_tag(:div, tags.html_safe, :class => "buy#{qualifier}")
    html.html_safe
  end

  def format_column_heading(options={})
    options.symbolize_keys!
    if CONFIG[:default_format_only] == true
      options[:always_display_price] == true ? 'Price' : '&nbsp;'.html_safe
    else
      'Format'
    end
  end
  
  def format_field(f, options={}, &block)
    # 'f' is the form variable
    options.symbolize_keys!
    if CONFIG[:default_format_only] == true
      hidden = f.hidden_field(:product_format_id)
      options[:always_display_price] == true ? "#{hidden} #{number_to_currency(f.object.product.default_price)}" : hidden
    else
      if block_given?
        format_options = f.object.product.product_formats.collect {|x| [(yield x), x.id]}
      else
        format_options = f.object.product.product_formats.collect {|x| [x.to_s, x.id]}
      end
      f.select(:product_format_id, format_options)
    end
  end
  
  def format_column_value(obj)
    return nil unless obj.is_a?(ProductFormat) || obj.is_a?(LineItem)
    obj = obj.product_format if obj.is_a?(LineItem)
    CONFIG[:default_format_only] == true ? '&nbsp;'.html_safe : obj.to_s
  end

  def product_subtype_options(options = {})
    tmp = Product::SUBTYPES.to_a
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end
  
  def format_options(options = {})
    # options: show_all, singles_only, include_blank, as
    if options[:show_all]
      formats = Format
    elsif options[:singles_only]
      formats = Format.find_single_units
    else
      formats = Format.where(:id => (CONFIG[:default_format_only] ? Format::DEFAULT_ID : CONFIG[:show_format_ids]))
    end
    if options[:as] == :integer
      tmp = formats.order(:name).map {|x| [x.name, x.id]}
    else
      tmp = formats.order(:name).map {|x| [x.name, x.id.to_s]}
    end
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end

  def status_options(options ={})
    # options: show_all, include_blank
    if options[:show_all] == true
      tmp = APP_STATUSES.sort.map{|x| [x[1]["value"], x[0]]}
    else
      tmp = ProductFormat.order(:status).group(:status).map{|pf| [APP_STATUSES[pf.status]["value"], pf.status]}
    end
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end

  def level_options(options = {})
    options[:adjust_by] ||= 0
    if options[:as] == :integer
      tmp = Level.visible.map {|x| [x.name, x.id + options[:adjust_by]]}
    else
      tmp = Level.visible.map {|x| [x.name, (x.id + options[:adjust_by]).to_s]}
    end
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end

  def reading_level_options(options = {})
    options[:adjust_by] ||= 0
    levels = Level.where("id >= ? AND id <= ?", Product.minimum(:reading_level_id), Product.maximum(:reading_level_id))
    if options[:as] == :integer
      tmp = levels.map {|x| [x.name, x.id + options[:adjust_by]]}
    else
      tmp = levels.map {|x| [x.name, (x.id + options[:adjust_by]).to_s]}
    end
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end

  def copyright_options(options = {})
    range = (Product.minimum(:copyright)..Date.today.year).to_a
    if options[:as] == :integer
      tmp = range
    else
      tmp = range.map {|x| x.to_s}
    end
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end

  def dewey_range_options(options = {})
    range = (0..999).to_a
    if options[:as] == :integer
      tmp = range.map {|x| [sprintf("%03d", x), x]}
    else
      tmp = range.map {|x| [sprintf("%03d", x), x.to_s]}
    end
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end

  def dewey_type_options(options = {})
    # tmp = [["All Fiction","F"], ["Biography","B"], ["Easy","E"], ["Numeric Range","RNG"]]
    tmp = [["All Fiction","F"], ["Biography","B"], ["Easy","E"]]
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end
  
  def alsreadlevel_options(options = {})
    range = ((Product.minimum(:alsreadlevel).floor.to_i)..(Product.maximum(:alsreadlevel).ceil.to_i)).to_a
    if options[:as] == :integer
      tmp = range.to_a.map {|x| [x, x]}
    else
      tmp = range.to_a.map {|x| [sprintf('%2.1f', x), x.to_s]}
    end
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end
  
  def lexile_options(options = {})
    range = ((Product.minimum(:lexile).floor.to_i)..(Product.maximum(:lexile).ceil.to_i)).to_a
    if options[:as] == :integer
      tmp = range.to_a.map {|x| [x, x]}
    else
      tmp = range.to_a.map {|x| [sprintf('%2.1f', x), x.to_s]}
    end
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end

  def boolean_options(options = {})
    tmp = [["Yes", true], ["No", false]]
    tmp.insert(0, "") if options[:include_blank] == true
    tmp
  end
  
  def display(value, label, options = {})
    # options: wrap = false, label_class = nil, value_id = nil, allow_nil = false
    if value.blank? && !options[:allow_nil]
      html = ''
    else
      html = (label.blank? ? '' : content_tag(:span, label + ": ", :class => options[:label_class])) + (options[:value_id].blank? ? value.to_s : content_tag(:span, value.to_s, :id => options[:value_id]))
      wrap = options[:wrap]
      [:wrap, :label_class, :value_id, :allow_nil].each {|k| options.delete(k)}
      html = content_tag(:li, html, options) if wrap == true
    end
  end
  
  def display_value(record, attribute, label=nil, conversion=nil, wrap=false, options = {})
    attribute = attribute.to_s
    value = record.send(attribute)
    value = conversion[value] unless conversion.nil?
    display(value.to_s.capitalize, (label.blank? ? attribute.humanize : label), options.merge(:wrap => wrap))
  end
  
  def display_value_in_list(record, attribute, label=nil, conversion=nil, options = {})
    display_value(record, attribute, label, conversion, true, options)
  end
  
  # Summary list for product
  def compact_price_listing(product, options = {}, &block)
    # options: include_title_count, include_label
    return unless CONFIG[:default_format_only] == true
    content = ""
    list_price = number_to_currency(product.default_price_list)
    price = number_to_currency(product.default_price)
    unless product.default_format.status == ProductFormat::ACTIVE_STATUS_CODE
      # Uncomment if price strikeout desired
      list_price = content_tag(:strike, list_price, :class => 'subdue')
      price = content_tag(:strike, price, :class => 'subdue')
    end
    extra = ""
    if options[:include_title_count] && product.respond_to?(:titles)
      extra = "(Set of #{link_to(pluralize(product.titles.count, 'title'), show_path(product, :anchor => 'titles'), :class => 'subdue')})"
    end
    price_label = options[:include_label] == true ? content_tag(:span, "Price: ") : ""
    content << content_tag(:li, price_label.html_safe + content_tag(:span, "<strong>#{price}</strong> / #{list_price} #{extra}".html_safe), :class => 'list-price')
    content += with_output_buffer(&block) if block_given?
    content_tag(:ul, content.html_safe)
  end

  def price_listing(product, options = {}, &block)
    # options: include_title_count
    return unless CONFIG[:default_format_only] == true
    content = ""
    list_price = number_to_currency(product.default_price_list)
    price = number_to_currency(product.default_price)
    unless product.default_format.status == ProductFormat::ACTIVE_STATUS_CODE
      # Uncomment if price strikeout desired
      list_price = content_tag(:strike, list_price, :class => 'subdue')
      price = content_tag(:strike, price, :class => 'subdue')
    end
    extra = ""
    if options[:include_title_count] && product.respond_to?(:titles)
      extra = "(Set of #{link_to(pluralize(product.titles.count, 'title'), show_path(product, :anchor => 'titles'), :class => 'subdue')})"
    end
    content << content_tag(:li, content_tag(:span, "Member Price: ") + content_tag(:span, "#{price} #{extra}".html_safe, :class => 'bold'), :class => 'member-price-big')
    content << display(list_price, 'List Price', :wrap => true, :class => 'list-price')
    content += with_output_buffer(&block) if block_given?
    content_tag(:ul, content.html_safe)
  end
  
  def series_link(product, options = {})
    if collection = product.series
      link_to(collection.name, collection, options)
    end
  end
  
  def subseries_link(product, options = {})
    if collection = product.subseries
      link_to(collection.name, collection, options)
    end
  end

  def interest_level_range_link(product)
    temp = product.interest_level_min.try(:name)
    min = link_to(temp, level_path(product.interest_level_min), :class => 'subdue') unless temp.blank?
    temp = product.interest_level_max.try(:name)
    max = link_to(temp, level_path(product.interest_level_max), :class => 'subdue') unless temp.blank?
    [min, max].compact.join(' - ').html_safe
  end
  
  def category_link(product, options = {})
    if product.categories.any?
      product.categories.map do |category|
        link_to(category.name, category_path(category), options)
      end.join(", ").html_safe
    end
  end
  
  def bisac_link(product)
    if product.bisac_subjects.any?
      product.bisac_subjects.map do |bs|
        link_to(bs.code, search_results_path(:bisac_subjects_code_in => bs.code), :class => 'subdue')
      end.join(", ").html_safe
    end
  end
  
  def subscribe_link(text='Subscribe', *args)
    return if CONFIG[:subscribe_url].blank?
    options = args.extract_options!.symbolize_keys
    html = link_to(text, subscribe_path)
    (options[:wrap] == true) ? content_tag(:li, html, :class => submenu_class_by_path('/subscribe')) : html
  end
  
  def unsubscribe_link(text='Unsubscribe', *args)
    return if CONFIG[:unsubscribe_url].blank?
    options = args.extract_options!.symbolize_keys
    html = link_to(text, unsubscribe_path)
    (options[:wrap] == true) ? content_tag(:li, html, :class => submenu_class_by_path('/unsubscribe')) : html
  end

  def cover_image_sized_link(product, text, url, *args)
    # Control styling using the div.photo class in public.css
    options = args.extract_options!.symbolize_keys
    html = link_to(text, url, options.merge(:style => "width:#{product.cover_image_width-10}px; height:#{product.cover_image_height-30}px;"))
    content_tag(:div, html, :class => "photo")
  end
  
  def product_name_with_count(product)
    (product.respond_to?(:titles) ? content_tag(:strong, "#{product.name} (#{pluralize(product.titles.count, 'title')})") : product.name)
  end
  
  def ssl_options
    Rails.env.production? ? {:only_path => false, :protocol => 'https'} : {}
  end
  
  def public_url
    case controller_name
    when 'users', 'sales', 'admin', 'errata', 'jobs', 'recipients', 'distribution'
      root_path
    when 'products', 'bundles'
      shop_path
    when 'pages'
      public_page_path(:help)
    when 'categories'
      categories_path
    when 'catalog_requests'
      new_catalog_request_path
    when 'collections'
      collections_path
    else
      "/#{controller_name}"
    end
  end
  
  def submenu_class(controller, action=[])
    controller = [controller] if controller.is_a?(String)
    action = [action] if action.is_a?(String)
    if action.any?
      return 'active' if controller.include?(controller_name) && action.include?(action_name)
    else
      return 'active' if controller.include?(controller_name)
    end
  end
  
  def submenu_class_by_path(path)
    return 'active' if path == request.fullpath.gsub(/\?.*/,'')
  end
  
  def app_select_options(meth)
    meth = meth.to_sym
    meth_map = {:default_role => :role}
    list_name = (meth_map.has_key?(meth) ? meth_map[meth] : meth)
    list = "APP_#{list_name.to_s.pluralize.upcase}".constantize
    list.sort{|a,b| a[0]<=>b[0]}.map{|k,v| [k, v['value']]}
  end
  
  def to_dropdown(a)
    if a[0].is_a?(Product)
      a.map{|x| [x.name_for_dropdown, x.id]}.uniq
    elsif a[0].respond_to?(:product)
      a.map{|x| [x.product.name_for_dropdown, x.product.id]}.uniq
    else
      a.map{|x| [x.name, x.id]}.uniq
    end
  end
  
  protected
  
  # When drawing each html menu item, we need to determine if it should be drawn as 'active'.
  # That determination is predicated on the current controller.
  # Fyi: We can 'force' a menu item to be drawn as 'active' but not here (see the calling method).
  def active_menu(item)
    case item
    when 'home'
      # control via @force_active, which can be defined in a controller or view
    when 'shop'
      is_active = controller_is?('CategoriesController','CheckoutController','EditorialReviewsController','ErrattaController','ExcerptsController','LevelsController','ProductsController','QuotesController','ShopController','WishlistsController')
    when 'account'
      is_active = controller_is?('AccountController','SpecsController','AddressesController')
    when 'about'
      is_active = controller_is?('HeadlinesController','TestimonialsController')
    when 'help'
      is_active = controller_is?('FaqsController','CatalogRequestsController','LinksController','DownloadsController')
    when 'catalog'
      is_active = controller_is?('Admin::ProductsController','Admin::CategoriesController','Admin::EditorialReviewsController','Admin::ContributorsController','Admin::LinksController', 'Admin::CollectionsController', 'Admin::FormatsController')
    when 'sales'
      is_active = controller_is?('SalesController','Admin::UsersController','Admin::BundlesController', 'Admin::SalesController')
    when 'content'
      is_active = controller_is?('Admin::CatalogRequestsController','Admin::ErrataController','Admin::FaqsController','Admin::HeadlinesController','Admin::PagesController','Admin::TestimonialsController','Admin::DownloadsController', 'Admin::TeachingGuidesController', 'Admin::HandoutsController')
    when 'management'
      is_active = controller_is?('Admin::JobsController','Admin::RecipientsController','Admin::PriceChangesController','Admin::DistributionController')
    else
      raise 'Unimplemented menu option: Update active_menu helper method'
    end
  end
  
  # This method determines if the current controller is within the list of options given (args)
  # It is used by 'active_menu' to determine if an html menu item should be drawn as 'active'
  def controller_is?(*args)
    args = [args] unless args.is_a?(Array)
    args.include?(controller.class.to_s)
  end
  
  def overwrite_content_for(name, content = nil, &block)
    @_content_for[name] = ""
    content_for(name, content, &block)
  end

  def glider_per(product)
    if CONFIG[:show_sidebar] && CONFIG[:show_panel]
      per = (product.default_format.width.to_f > 8.5 ? 2 : 3)
    else
      per = (product.default_format.width.to_f > 8.5 ? 3 : 4)
    end
  end

  def toggle_filter_link_to(title, filter_name)
    link_to_function title, "$('#{filter_name}_filter').toggle(); $$('.#{filter_name}_field').each(function(v){v.disabled = !v.disabled})"
  end

  def filter_slider(field, name, limits=[0,10000000], delimiter='', description='Range')
    min = params["#{field}_from"]
    max = params["#{field}_to"]
    disabled = min.blank? && max.blank?
    min = limits.first if min.blank?
    max = limits.last  if max.blank?
    render :partial => "slider", :locals => {
      :field       => field,
      :name        => name,
      :min         => min,
      :max         => max,
      :range       => limits.join(', '),
      :disabled    => disabled,
      :delimiter   => delimiter,
      :description => description,
    }
  end
  
  def filter_checkboxes(field, name, values_hash=nil, values=nil)
    values_hash ||= params[field]
    values||= params[field]
    disabled = (values.blank? or (values.to_a.size == 1 and values.to_a.first.blank?))
    values_hash = values_hash.split(/,\s*/) if values_hash.is_a?(String)
    values_hash = values_hash.inject({}) {|h,e| (e.is_a?(Array) ? h[e[0]] = e[1] : h[e] = e); h} if values_hash.is_a?(Array)
    values ||= []
    values = values.split(/,\s*/) if values.is_a?(String) || values.nil?
    values = values.to_a if values.is_a?(Hash)
    render :partial => "checkboxes", :locals => {
      :field       => field,
      :name        => name,
      :values_hash => values_hash,
      :values      => values,
      :disabled    => disabled,
    }
  end

  def clean_params
    params.delete_if do |k, v|
      %w(authenticity_token commit l x y).include?(k) || v.blank?
    end
  end

  def byline(product)
    if product.respond_to?(:titles)
      html = "of " + link_to(pluralize(product.titles.count, "title"), show_path(product, :anchor => 'titles'))
      content_tag(:p, content_tag(:span, "Set ") + content_tag(:em, html.html_safe), :class => "byline")
    else
      return if product.author.blank?
      html = product.author.split(" and ").map {|x| content_tag(:span, x)}.join(" and ")
      content_tag(:p, content_tag(:em, "by ") + html.html_safe, :class => "byline")
    end
  end
end
