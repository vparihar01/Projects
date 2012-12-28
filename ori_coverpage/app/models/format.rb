class Format < ActiveRecord::Base
  has_many :products, :through => :product_formats
  has_many :product_formats
  
  validates :name, :uniqueness => true
  validates :form, :inclusion => { :in => APP_FORMS.keys }, :allow_blank => true
  validates :detail, :inclusion => { :in => APP_DETAILS.keys }, :allow_blank => true
  
  before_save :check_default, :check_pdf
  
  DEFAULT_ID = (find_by_is_default(true) ? find_by_is_default(true).id : 1)
  PDF_ID = (find_by_is_pdf(true) ? find_by_is_pdf(true).id : 2)
  TRADE_ID = 3
  
  def self.find_single_units
    where("units = 1")
  end
  
  def self.to_dropdown
    order(:name).collect {|f| [f.name, f.id]}
  end
  
  protected
  
    # Ensure table has only one record flagged as default
    def check_default
      other_default = Format.count(:conditions => ['is_default = ? AND id != ?', true, self.id])
      if self.is_default
        Format.update_all('is_default = 0') if other_default > 0
      end
      true
    end
    
    # Ensure table has only one record flagged as pdf
    def check_pdf
      other_pdf = Format.count(:conditions => ['is_pdf = ? AND id != ?', true, self.id])
      if self.is_pdf
        Format.update_all('is_pdf = 0') if other_pdf > 0
      end
      true
    end
    
end
