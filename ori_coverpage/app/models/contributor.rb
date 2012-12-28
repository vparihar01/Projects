class Contributor < ActiveRecord::Base
  has_many :contributor_assignments, :order => :role, :dependent => :destroy
  has_many :products, :through => :contributor_assignments, :order => :name

  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :default_role, :inclusion => { :in => APP_ROLES.keys }
  
  def name_less_article
    self.name.gsub(/^(Dr\.|Mr\.|Miss|Mrs\.|Professor) /i, '')
  end
  
  def self.to_dropdown
    all.sort_by(&:name_less_article).collect {|x| [x.name, x.id]}
  end
  
  def name_inverted
    return unless self.name?
    if result = /(.*) (and|&) (.*)/.match(self.name)
      "#{Name.inverted(result[1])} and #{Name.inverted(result[3])}"
    else
      Name.inverted(self.name)
    end
  end
  
  def name_first
    if parsed = Name.parse(self.name)
      parsed[:first_name]
    else
      nil
    end
  end
  
  def name_last
    if parsed = Name.parse(self.name)
      parsed[:last_name]
    else
      nil
    end
  end

  def merge(source, options = {})
    FEEDBACK.verbose "Updating contributor assignments (#{source.id} => #{self.id})..." if verbose
    rows = ActiveRecord::Base.connection.update("UPDATE contributor_assignments SET contributor_id = '#{self.id}' WHERE contributor_id = '#{source.id}'") unless debug
    FEEDBACK.verbose "  #{rows} row(s) affected..." if verbose && rows
    # merge data
    [:description, :default_role].each do |col|
      if self.send(col).blank? && !source.send(col).blank?
        self.update_attribute(col, source.send(col)) unless debug
      end
    end
    FEEDBACK.verbose "Destroying contributor (#{source.id})..." if verbose
    source.destroy unless debug
  end
  
end
