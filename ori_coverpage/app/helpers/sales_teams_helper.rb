module SalesTeamsHelper
  def delta_to_percentage(current, prev)
    percentage = prev > 0 ? (current / prev.to_f) - 1 : 1
    number_to_percentage(percentage * 100, :precision => 1)
  end
end
