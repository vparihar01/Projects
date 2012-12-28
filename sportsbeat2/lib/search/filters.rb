module Search
  module Filters
    def self.hs_name_filters
      h = {}
      h.merge!(metaphone_filters)
      h.merge!(ngram_filters)
      h.merge!({
        :hs_name_stopwords => {
          :type => :stop,
          :stopwords => [
            'of', 'the',
            'high', 'highschool',
            'middle', 'middleschool',
            'elementary', 'junior', 'senior',
            'school', 'academy'
          ]
        }
      })

      return h
    end

    def self.metaphone_filters
      return {
        :metaphone => {
          :replace => false,
          :encoder => :metaphone,
          :type => :phonetic
        }
      }
    end

    def self.ngram_filters
      return {
        :edge_ngrams => {
          :side => :front,
          :max_gram => 16,
          :min_gram => 1,
          :type => :edgeNGram
        },
        :ngrams => {
          :max_gram => 5,
          :min_gram => 2,
          :type => :nGram
        }
      }
    end

    def self.team_filters
      h = {}
      h.merge!(hs_name_filters)
      h.merge!(metaphone_filters)
      h.merge!(ngram_filters)
      h.merge!({
        :team_name_synonyms => {
          :type => :synonym,
          :synonyms => [
            "jr varsity, jr. varsity, jr.varsity, jrvarsity, junior varsity => jrvarsity",
            "freshmen => freshman"
          ]
        }
      })

      return h
    end

    def self.user_filters
      return ngram_filters.merge!(metaphone_filters)
    end
  end
end