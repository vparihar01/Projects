class ProductsParserJob < Struct.new(:file_path, :options)
  def perform
    ProductsParser.execute(file_path, options)
  end
end
