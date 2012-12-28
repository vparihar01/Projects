class Sport < ActiveRecord::Base
  attr_accessible :name, :gender_code

  has_many :positions
  has_many :teams
  
  validates :name, :presence => true
  validates :name, :uniqueness => true
  validates :gender_code, :inclusion => {:in => ['m', 'w', 'm,w', 'mw']}

  def self.for_gender(g)
    if g == 'male' || g == 'm' || g == 'b'
      return Sport.where(:gender_code => ['m', 'm,w', 'mw']).order('name ASC')
    elsif g == 'female' || g == 'f' || g == 'w' || g == 'g'
      return Sport.where(:gender_code => ['w', 'm,w', 'mw']).order('name ASC')
    else
      return Sport.all.order('name ASC')
    end
  end

  def genders
    gender_code.split(',')
  end

  def gender_code_for(user)
    if user.gender == 'male' ||user.gender == 'm' ||user.gender == 'b'
      return genders.include?('mw') ? 'mw' : 'm'
    elsif user.gender == 'female' || user.gender == 'f' ||user.gender == 'w' || user.gender== 'g'
      return genders.include?('mw') ? 'mw' : 'w'
    else
      return 'mw'
    end
  end

end
