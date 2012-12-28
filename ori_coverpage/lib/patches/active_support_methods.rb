class Array
  def in_vertical_groups_of(number, fill_with = nil, &block)
    return in_groups_of((size.to_f / number).ceil, fill_with, &block).transpose
  end
end
