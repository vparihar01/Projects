module TaggableHelper
  def tag_list_to_links(tags, *args)
    options = args.extract_options!.symbolize_keys
    # default options
    options[:label] ||= "all"
    options[:show_all] ||= false
    options[:join_with] ||= ", "
    # code directly dependent on route helper of appropriate format
    links = tags.map{|tag| params[:tag] == tag.name ? tag.name : link_to(tag.name, eval("tag_#{controller.controller_name}_path('#{tag.name}')"))}
    links.unshift(tags.map(&:name).include?(params[:tag]) ? link_to(options[:label], eval("#{controller.controller_name}_path")) : options[:label]) if options[:show_all]
    links.join(options[:join_with])
  end
end
