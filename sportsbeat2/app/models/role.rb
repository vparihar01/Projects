class Role < ActiveRecord::Base
  attr_accessible :name
  has_and_belongs_to_many :users
  validates :name, :presence => true

  module Helpers
    def has_roles *names
      names.each do |name|
        name_str = name.to_s
        scope name_str.pluralize.to_sym, lambda { joins(:roles).where(:roles => {:name => name_str}) }

        define_method "#{name}?" do
          roles.find_by_name name
        end

        define_method "has_role?" do |n|
          roles.find_by_name n
        end

        has_and_belongs_to_many :roles
      end
    end
  end

end