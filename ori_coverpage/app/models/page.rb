class Page < ActiveRecord::Base
  # Do not allow creation of pages with the following path
  CONTROLLER_ACTIONS = PagesController.action_methods.freeze
  EXTRA_EXCLUDE_PATHS = %w(view index show new create edit update destroy).freeze
  LAYOUTS = (Dir.glob('app/views/layouts/*') + Dir.glob("app/themes/#{CONFIG[:theme]}/views/layouts/*")).map{|f| File.basename(f).gsub(/\..*/, '')}.delete_if{|f| %w(error administration).include?(f) || f =~ /^admin_/}.uniq.compact.sort

  validates :title, :presence => true
  validates :path, :presence => true, :uniqueness => true, :exclusion => { :in => CONTROLLER_ACTIONS + EXTRA_EXCLUDE_PATHS }
  validates :layout, :inclusion => { :in => LAYOUTS }, :allow_blank => true

end
