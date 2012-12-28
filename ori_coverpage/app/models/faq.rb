class Faq < ActiveRecord::Base
  acts_as_taggable
  include TaggableModelMethods

  validates :question, :presence => true
  validates :answer, :presence => true
  
end