# Code derived from:
#   skojin -- https://github.com/skojin/counter_cache_with_conditions
#   scott windsor -- https://github.com/rails/rails/issues/647

module CounterCache
  def self.included(target)
    target.extend ClassMethods
  end
  
  module ClassMethods
    # @param association_name extended belongs_to association name (like :user)
    # @param counter_name name of counter cache column
    # @param conditions lambda{|read, source| read == false && source == 'message'}
    def counter_cache(association_name, counter_name, conditions)
      unless ancestors.include? InstanceMethods
        include InstanceMethods
        after_create :counter_cache_after_create
        before_update :counter_cache_before_update
        before_destroy :counter_cache_before_destroy

        cattr_accessor :counter_cache_options
        self.counter_cache_options = []
      end

      ref = self.reflections[association_name]
      ref.klass.send(:attr_readonly, counter_name.to_sym) if ref.klass.respond_to?(:attr_readonly)
      self.counter_cache_options << [ref.klass, ref.association_foreign_key, counter_name, conditions]
    end
  end

  module InstanceMethods
    private

    def counter_cache_after_create
      self.counter_cache_options.each do |counter_klass, counter_foreign_key, counter_name, counter_conditions|
        association_id = send(counter_foreign_key)
        if !association_id.blank? && (!counter_conditions || counter_conditions.call(self))
          counter_klass.increment_counter(counter_name, association_id)
        end
      end
    end
    
    def counter_cache_before_update
      self.counter_cache_options.each do |counter_klass, counter_foreign_key, counter_name, counter_conditions|
        association_id_was = send("#{counter_foreign_key}_was")
        association_was = association_id_was.blank? ? nil : counter_klass.find(association_id_was)
        association_id = send(counter_foreign_key)
        association = association_id.blank? ? nil : counter_klass.find(association_id)
        if counter_conditions
          conditional_was = counter_conditions.call(without_changes)
          conditional_is = counter_conditions.call(self)
          if (conditional_was == true) && (conditional_is == false) && send("#{counter_foreign_key}_changed?")
            # decrement only old, if association changed and condition broken
            counter_klass.decrement_counter(counter_name, association_was.id) unless association_was.nil?
          elsif (conditional_was == true) && (conditional_is == false)
            counter_klass.decrement_counter(counter_name, association.id) unless association.nil?
          elsif (conditional_was == true) && (conditional_is == true) && send("#{counter_foreign_key}_changed?")
            # if just association changed, decrement old, increment new
            counter_klass.decrement_counter(counter_name, association_was.id) unless association_was.nil?
            counter_klass.increment_counter(counter_name, association.id) unless association.nil?
          elsif (conditional_was == false) && (conditional_is == true)
            counter_klass.increment_counter(counter_name, association.id) unless association.nil?
          end
        end
      end
    end
    
    def counter_cache_before_destroy
      self.counter_cache_options.each do |counter_klass, counter_foreign_key, counter_name, counter_conditions|
        association_id = send(counter_foreign_key)
        if !association_id.blank? && (!counter_conditions || counter_conditions.call(self))
          counter_klass.decrement_counter(counter_name, association_id)
        end
      end
    end

    def without_changes
      original = self.clone
      original.id = self.id
      original.attributes = changed.inject({}) {|h, attr| h[attr] = attribute_was(attr); h }
      original
    end

  end
end
