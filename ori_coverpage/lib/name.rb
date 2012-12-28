# http://artofmission.com/articles/2009/5/31/parse-full-names-with-ruby

class Name < ActiveRecord::Base

  def self.parse(name)
    return false unless name.is_a?(String)
    
    # First, split the name into an array
    parts = name.split
    
    # If any part is "and", then put together the two parts around it
    # For example, "Mr. and Mrs." or "Mickey and Minnie"
    parts.each_with_index do |part, i|
      if ["and", "&"].include?(part) and i > 0
        p3 = parts.delete_at(i+1)
        p2 = parts.at(i)
        p1 = parts.delete_at(i-1)
        parts[i-1] = [p1, p2, p3].join(" ")
      end
    end
    
    # Build a hash of the remaining parts
    {
      :suffix => (s = parts.pop unless parts.last !~ /(\w+\.|[IVXLM]+|[A-Z]+)$/),
      :last_name  => (l = parts.pop.gsub(/,$/, '') if parts.size > 0),
      :prefix => (p = parts.shift unless parts[0] !~ /^(\w+\.|Professor)/),
      :first_name => (f = parts.shift),
      :middle_name => (m = parts.join(" "))
    }
  end
  
  def self.inverted(name)
    parsed_name = parse(name)
    return false unless parsed_name.is_a?(Hash)
    str = ""
    unless parsed_name[:last_name].blank?
      str += "#{parsed_name[:last_name]}, "
    end
    unless parsed_name[:first_name].blank?
      str += "#{parsed_name[:first_name]} "
    end
    unless parsed_name[:middle_name].blank?
      str += "#{parsed_name[:middle_name]}"
    end
    str.strip
  end

end
