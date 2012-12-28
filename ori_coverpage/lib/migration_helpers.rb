module MigrationHelpers
  def decimalize_column(model_name, old_column, new_column)
    rename_column model_name.table_name, old_column, new_column
    change_column model_name.table_name, new_column, :decimal, :precision => 11, :scale => 2
    # model_name.reset_column_information
    # model_name.all.each do |row|
    #   unless row[new_column] == nil
    #     row.update_attribute new_column, row[new_column] / 100
    #   end
    # end
  end

  def undecimalize_column(model_name, old_column, new_column)
    # model_name.all.each do |row|
    #   unless row[new_column] == nil
    #     row.update_attribute new_column, row[new_column] * 100
    #   end
    # end
    change_column model_name.table_name, new_column, :integer
    rename_column model_name.table_name, new_column, old_column
  end
  
  def decimalize_data(model_name, new_column)
    model_name.reset_column_information
    model_name.all.each do |row|
      unless row[new_column] == nil
        row.update_attribute new_column, row[new_column] / 100
      end
    end
  end

  def undecimalize_data(model_name, new_column)
    model_name.all.each do |row|
      unless row[new_column] == nil
        row.update_attribute new_column, row[new_column] * 100
      end
    end
  end
end