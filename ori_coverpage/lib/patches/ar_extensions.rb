module ActiveRecord
  class Base
    class << self
      def find_random(i=1)
        order("RAND()").limit(i).all
      end
      
      def find_latest(i=2, column="created_at")
        order("#{column} DESC").limit(i).all
      end
    end
  end
end
