module Search
  module Analyzers
    def self.ngram_analyzers
      return {
        :ngram_analyzer => {
          :type => :custom,
          :tokenizer => :standard,
          :filter => [
            :standard,
            :asciifolding,
            :lowercase,
            :ngrams
          ]
        },
        :edge_ngram_analyzer => {
          :type => :custom,
          :tokenizer => :standard,
          :filter => [
            :standard,
            :asciifolding,
            :lowercase,
            :edge_ngrams
          ]
        }
      }
    end

    def self.hs_name_analyzers
      return {
        :hs_name_analyzer => {
          :type => :custom,
          :tokenizer => :standard,
          :filter => [
             :standard,
             :lowercase,
             :asciifolding,
             :hs_name_stopwords,
             :edge_ngrams
          ],
        },
      }
    end

    def self.team_analyzers
      h = {}
      h.merge!(hs_name_analyzers)
      h.merge!(user_analyzers)

      h.merge!({
        :team_name_analyzer => {
          :type => :custom,
          :tokenizer => :standard,
          :filter => [
             :standard,
             :asciifolding,
             :lowercase,
             :team_name_synonyms,
             :metaphone,
             :ngrams
          ],
        }
      })

      return h
    end

    def self.user_analyzers
      return {
        :user_name_analyzer => {
          :type => :custom,
          :tokenizer => :standard,
          :filter => [
             :standard,
             :asciifolding,
             :lowercase,
             :metaphone,
             :edge_ngrams
          ],
        }
      }
    end

  end
end