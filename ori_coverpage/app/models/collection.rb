# Assumptions:
# - Collection should be associated with Assemblies by same name
# - Collection should also be associated with aforementioned Assembly titles

class Collection < ActiveRecord::Base
  has_many :products, :dependent => :nullify
  has_many :titles, :order => :name
  has_many :assemblies, :order => :name
  validates :name, :presence => true # Removed uniqueness restriction due to childsworld
  acts_as_tree :dependent => :nullify
  
  scope :has_available_products, where("available_products_counter > 0")
  scope :name_like, lambda { |name|
    where( name.blank? ? '' : ["name LIKE ?", "%#{name}%"] )
  }

  scope :released, where("released_on <= NOW()")

  def self.to_dropdown
    all.sort_by(&:name_less_article).collect {|s| [s.name_for_dropdown, s.id]}
  end
  
  def name_for_dropdown
    "#{self.name}"
  end
  
  def name_less_article
    self.name.gsub(/^(A|An|The) /i, '')
  end

  def name_extended
    # Option 1: Add root to name
    # if self.parent
    #   "#{self.root.name}: #{self.name}"
    # else
    #   self.name
    # end
    # Option 2: Add parent to name
    # if self.parent
    #   "#{self.parent.name}: #{self.name}"
    # else
    #   self.name
    # end
    # Option 3:
    #   Add parent if subseries
    #   Use root + parent if sub-subseries
    if self.parent
      # not root: some type of subseries
      if self.parent.name == self.root.name
        # subseries
        prefix = self.parent.name
        suffix = self.name
      else
        # sub-subseries
        prefix = self.root.name
        suffix = self.parent.name
      end
      if /^#{prefix}/.match(suffix)
        # avoid redundancies in prefix
        suffix
      else
        "#{prefix}: #{suffix}"
      end
    else
      # root: main series
      self.name
    end
  end
  
  # Change routing. Use name not id.
  def to_param
    "#{self.id}-#{self.name.gsub(/[^a-z1-9]+/i, '-').downcase}"
  end
  
  # Collection available before today and after 'new_on' date
  def new?
    (!self.released_on.nil? && self.released_on >= Product.new_on)
  end

  # Collection released before today
  def released?
    (!self.released_on.nil? && self.released_on <= Date.today)
  end

  # Pass-through to obtain image of first title in collection
  def image(type = "covers", size = "s")
    if sample = self.assemblies.order(:available_on).try(:first)
      sample.image(type, size)
    elsif sample = self.titles.order(:available_on).try(:first)
      sample.image(type, size)
    else
      "no-photo.gif"
    end
  end

  def self.create_from_assembly(assembly)
    FEEDBACK.debug("create_from_assembly")
    assembly = Assembly.find(assembly) if assembly.is_a?(Integer)
    FEEDBACK.print_record(assembly)
    collection_name = assembly.name.sub(/^.*: /, '')
    if collection = self.find_by_name(collection_name)
      FEEDBACK.warning("Collection (#{collection.id}) by same name of assembly (#{assembly.id}) already exists")
    else
      data = {:name => collection_name, :released_on => assembly.available_on, :description => assembly.description, :parent_id => assembly.collection_id}
      collection = self.create(data)
    end
    collection.assign_assembly(assembly)
    collection
  end

  # When assigning assembly, must also assign titles
  def assign_assembly(assembly)
    FEEDBACK.debug("assign_assembly")
    assembly = Assembly.find(assembly) if assembly.is_a?(Integer)
    FEEDBACK.print_record(assembly)
    # Assign assembly and titles to self
    self.products << assembly
    self.products << assembly.titles
  end

  # When removing assembly, must also remove titles
  def remove_assembly(assembly)
    FEEDBACK.debug("remove_assembly")
    assembly = Assembly.find(assembly) if assembly.is_a?(Integer)
    FEEDBACK.print_record(assembly)
    # Remove assembly and titles from self
    self.products.delete(assembly)
    self.products.delete(assembly.titles)
  end

  def self.no_products
    # Eager loading products does not improve speed -- does Rails cache products count?
    all.select {|collection| collection.products.empty?}
  end

  # Assign assemblies (and its titles) to collections that have matching names
  def self.fix_no_products
    FEEDBACK.debug("fix_no_products")
    no_products.each do |collection|
      collection.assign_assemblies_by_name
    end
  end

  # When removing assembly, must also remove titles
  def remove_assemblies_by_name
    Assembly.where("name = ? or name = ?", self.name, self.name_extended).all.each do |assembly|
      remove_assembly(assembly)
    end
  end

  # When assigning assembly, must also assign titles
  def assign_assemblies_by_name
    Assembly.where("name = ? or name = ?", self.name, self.name_extended).all.each do |assembly|
      assign_assembly(assembly)
    end
  end

  # When destroying a collection, it's products should be moved to parent
  def assign_products_to_parent
    self.parent.products << self.products if self.parent
  end

  # A cleanup tool, ensuring assembly titles are also assigned to collection
  def update_titles_per_assemblies
    self.assemblies.each do |assembly|
      self.products << assembly.titles
    end
  end

end
