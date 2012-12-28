# http://weblog.redlinesoftware.com/2008/1/30/willpaginate-and-remote-links
# Updated for WillPaginate 3.0
class RemoteLinkRenderer < WillPaginate::ActionView::LinkRenderer
  def prepare(collection, options, template)
    @remote = options.delete(:remote) || {}
    super
  end

  private

  def link(text, target, attributes = {})
    if target.is_a? Fixnum
      attributes[:rel] = rel_value(target)
      target = url(target)
    end
    attributes[:href] = target
    @template.link_to_function(text.to_s.html_safe, @template.remote_function({:url => target}.merge(@remote)), attributes)
  end
end
