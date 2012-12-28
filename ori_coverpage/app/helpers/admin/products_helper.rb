module Admin::ProductsHelper
  require 'lib/versioned_helper'
  include VersionedHelper

  def loc_link(product, options = {})
    if product.lccn.blank? || options[:force_search_by_isbn] == true
      url = "http://catalog.loc.gov/cgi-bin/Pwebrecon.cgi?v3=1&Search%5FArg=#{product.isbn}&Search%5FCode=STNO&CNT=1&SID=1"
    else
      url = "http://lccn.loc.gov/#{product.lccn}"
    end
    link_to("Library of Congress", url_for(url), :rel => 'external', :class => 'extlink')
  end
end
