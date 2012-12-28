module Search
  def self.find_game_by_date_and_location date, latitude, longitude
    pos = "#{latitude},#{longitude}"
    b = date.beginning_of_day.utc.strftime("%FT%T.%3NZ")
    e = date.end_of_day.utc.strftime("%FT%T.%3NZ")

    r = Tire.search "games" do
      query { range :datetime, :gte => b, :lte => e } 
      sort { by :_geo_distance, :location => pos, :order => :asc, :unit => :mi }
      filter :geo_distance, :distance => "20mi", :location => pos
      size 5
    end

    return r.results
  end

  def self.find_school(what, options = {})
    limit = [options[:limit].to_i, 5].max
    offset = [options[:offset].to_i, 0].max

    query_body = {
      :bool => {
        :must => [
          { :text => { :name => what } }
        ],
      }
    }

    q = {
      :size => limit,
      :from => offset,
      :query => query_body
    }

    if !options[:latitude].blank? && !options[:longitude].blank?
      lat = options[:latitude].to_f
      lon = options[:longitude].to_f
      q[:query] = {
        :custom_score => {
          :query => query_body,
          :script => "_score * (_score / doc['location'].distance(#{lat},#{lon}))"
        }
      }
    end

    return Tire.search('schools', q).results
  end

  def self.find_user(what, options = {})
    limit = [options[:limit].to_i, 5].max
    offset = [options[:offset].to_i, 0].max

    query_body = {
      :bool => {
        :must => [
          { :text => { :name => what } }
        ],
        :must_not => [
          { :term => { :role => 'admin' } }
        ],
        :should => []
      }
    }

    q = {
      :size => limit,
      :from => offset,
      :query => query_body
    }

    if options[:user_ids]
      user_ids = Array(options[:user_ids]).map{|uid| uid.to_i }
      q[:query][:bool][:must] << {
        :terms => {
          :id => user_ids
        }
      }
    end

    if options[:preferred_user_ids]
      user_ids = Array(options[:preferred_user_ids]).map{|uid| uid.to_i}
      unless user_ids.empty?
        q[:query][:bool][:should] << {
          :terms => {
            :id => user_ids
          }
        }
      end
    end

    if options[:exclude_user_ids]
      excludes = Array(options[:exclude_user_ids]).map{|e| e.to_i }
      q[:query][:bool][:must_not] << {
        :terms => {
          :id => excludes
        }
      }
    end

    return Tire.search("users", q).results
  end
end