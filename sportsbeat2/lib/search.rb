require "search/analyzers.rb"
require "search/filters.rb"
require "search/finders.rb"

module Search
  module ReloadHelper
    def self.included(base)
      base.extend (ClassMethods)
    end

    module ClassMethods
      def reload_search_index(relation=self)
        self.tire.index.delete
        self.tire.create_elasticsearch_index

        relation.find_in_batches :batch_size => 1000 do |batch|
          self.tire.index.import batch
        end
      end
    end
  end
end