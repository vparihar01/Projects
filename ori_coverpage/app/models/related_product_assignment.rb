class RelatedProductAssignment < ActiveRecord::Base
  
  class NonCircularValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors[attribute] << "cannot refer to itself (circular reference)" if record.product_id == value
    end
  end
  
  class UniqueValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      rpas = RelatedProductAssignment.where("relation = ? and product_id = ? and related_product_id = ?", record.relation, record.product_id, record.related_product_id)
      rpas = rpas.where("id != ?", record.id) if record.id
      record.errors[attribute] << "between given products must be unique" if rpas.first
    end
  end
  
  class ReplacedOnlyOnceValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      if record.relation == RelatedProductAssignment::REPLACED_ID
        rpas = RelatedProductAssignment.where("relation = ? and product_id = ?", RelatedProductAssignment::REPLACED_ID, record.product_id)
        rpas = rpas.where("id != ?", record.id) if record.id
        record.errors[attribute] << "cannot have multiple replacements" if rpas.first
      end
    end
  end
  
  belongs_to :product
  belongs_to :related_product, :class_name => "Product"
  belongs_to :similar_product, :class_name => "Product", :foreign_key => "related_product_id"
  validates :product_id, :presence => true, :replaced_only_once => true
  validates :related_product_id, :presence => true, :non_circular => true
  validates :relation, :inclusion => { :in => APP_RELATIONS.keys }, :unique => true
  
  REPLACED_ID = 'Replaced'
  SIMILAR_ID = 'Similar'
  
  def to_s
    self.relation
  end
end
