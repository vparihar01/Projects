class RemoveRepsFromPagesTable < ActiveRecord::Migration
  def self.up
    if page = Page.find_by_path("reps")
      page.destroy
    end
  end

  def self.down
    data = {
      :title => "Sales Representatives",
      :body => "<h1>Sales Representatives</h1>",
      :path => "reps",
      :layout => "about",
    }
    page = Page.new(data)
    # NB: skipping validations because 'reps' is a reserved path
    page.save(:validate => false)
  end
end
