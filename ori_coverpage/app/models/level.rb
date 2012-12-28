class Level < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => {:case_sensitive => false}
  validates_numericality_of :value, :only_integer => true
  validates_uniqueness_of :value
  
  FILTER_RANGE = [(Level.minimum(:id) || 1) - 2, (Level.maximum(:id) || 8) - 2]

  # Change routing. Use name not id.
  def to_param
    abbreviation
  end

  scope :visible, where("is_visible = ?", true)

  def self.setup
    values = []
    values << "1, 'Preschool', 'P'"
    values << "2, 'Kindergarten', 'K'"
    (1..12).each do |i|
      values << "#{i+2}, 'Grade #{i}', '#{i}'"
    end
    sql = ActiveRecord::Base.connection()
    sql.execute "TRUNCATE #{self.table_name}"
    values.each do |value|
      sql.execute "INSERT INTO `#{self.table_name}` (id, name, abbreviation, is_visible, created_at, updated_at) VALUES (#{value}, 0, NOW(), NOW())"
    end
    set_visibility
  end

  # Visibility is predicated on the setup class method
  # Level id must be 2 greater than value (see similarly named instance method)
  # That is, ids must be: preschool = 1, kindergarten = 2, grade 1 = 3, etc
  def self.set_visibility
    min = Product.minimum(:interest_level_min_id)
    max = Product.maximum(:interest_level_max_id)
    all.each do |level|
      level.update_attribute(:is_visible, (level.id >= min && level.id <= max))
    end
  end

  # Level id must be 2 greater than value
  # That is, ids must be: preschool = 1, kindergarten = 2, grade 1 = 3, # etc
  def value
    id - 2
  end
  
  def to_s
    name
  end

end
