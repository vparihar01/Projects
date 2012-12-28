require 'delegate'

# A Season is defined as the period July 1 to June 30
# The Season running July 1, 2011 to June 30, 2012 is identified
# as season # 2012

class Season < DelegateClass(Fixnum)
  def initialize d = nil
    d ||= Date.today

    if d.class == Date
      super Season.find_id_by_date d
    else
      super d.to_i
    end
  end

  def self.current
    Season.new
  end

  def self.find_id_by_date date
    y = date.year
    y = y + 1 if date.month >= 7
    return y
  end

  def display_name
    "#{self-1}-#{self}"
  end

  def id
    self.to_i
  end
end

# module Arel
#   module Visitors
#     class ToSql
#       def visit_Season s
#         s.id
#       end
#     end
#   end
# end