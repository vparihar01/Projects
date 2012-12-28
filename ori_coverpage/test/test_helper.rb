ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
#  include AuthenticatedTestHelper
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  fixtures :all

  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  
  protected
  
    def valid_contract(options = {})
      { :sales_zone => sales_zones(:south_alabama),
        :sales_team => sales_teams(:bobby), 
        :rate => 0.25, :start_on => Time.now.to_s, 
        :category => 'All' }.merge(options)
    end
    
    def valid_customer(options = {})
      { :name => 'Foo', 
        :email => 'foo@example.com',
        :password => 'barrio',
        :password_confirmation => 'barrio',
        :category => 'School'}.merge(options)
    end

    def create_cart(user = nil)
      (@cart = Cart.create(:user => user)).add_item(Product.find(1).product_formats[0], 1)
      @cart
    end
    
    def valid_quote(options = {})
      { 'name' => 'Foo' }.merge(options)
    end
    
    def valid_quote_with_lines(options = {})
      { 'name' => 'Foo', "line_items_attributes" => {0 => {"product_format_id" => 1, "quantity" => 1}, 1 => {"product_format_id" => 2, "quantity" => 5}} }.merge(options)
    end
    
    def collect_items(cart, reload = false)
      cart.line_items(reload).collect {|i| [i.product_format_id, i.quantity]}
    end
    
    def ups_rate_list
      [ OpenStruct.new(
          :service_code => '03',
          :label => 'UPS Ground',
          :cost => CONFIG[:free_shipping_for_institutions] ? 50.0 : 37.5, # TODO make sure this number matches what HAS TO BE CALCULATED (it is what is calculated now)
          :description => CONFIG[:shipping_description_ups] ? CONFIG[:shipping_description_ups] : ''),
        OpenStruct.new(
          :service_code => '12',
          :label => 'Three-day select',
          :cost => 10.07,
          :description => '') ]
    end
  
    def valid_card(attributes = {})
      { :first_name => 'Joe', 
        :last_name => 'Doe',
        :month => 2, 
        :year => Time.now.year + 1, 
        :number => '1', 
        :card_type => 'bogus', 
        :verification_value => '123' 
      }.merge(attributes)
    end

    def valid_faq(options = {})
      { 'question' => 'how does a valid faq look like?',
        'answer' => 'it has at least a question and an answer and optionally a comma separated list of tags' }.merge(options)
    end

    def valid_link(options = {})
      { 'title' => 'Ruby-On-Rails',
        'url' => 'http://rubyonrails.org',
        'description' => 'Web development that doesn\'t hurt' }.merge(options)
    end

    def valid_page(options = {})
      { 'title' => 'Test Page',
        'body' => '<h1>Test Page</h1><br>Hello World!',
        'path' => 'test_page' }.merge(options)
    end

    def valid_contributor(options = {})
      { 'name' => 'Tom Test',
        'description' => 'A test contributor',
        'default_role' => 'Author' }.merge(options)
    end

    def valid_contributor_assignment(options = {})
      { 'contributor_id' => '5',
        'product_id' => '2',
        'role' => 'Designer'
      }
    end

    def valid_editorial_review(options =  {})
      {
        'source' => 'milkfarmproductions',
        'body' => 'a valid review'
      }
    end
    def valid_address(options = {})
      {
        'name' => 'Test Visitor',
        'attention' => 'John Doe',
        'street' => 'g-33-k on the street',
        'suite' => 'suite',
        'city' => 'San Diego',
        'country_id' => '1'
      }
    end
    def valid_catalog_request(options =  {})
      {
        'catalog_request' => { 'address_attributes' => valid_address },
        'postal_code' => { 'name' => '96143', 'zone_id' => '3' }
      }
    end
    def valid_testimonial(options =  {})
      {
        'name' => 'The guy downstairs',
        'company' => 'Bad company',
        'location' => 'Upstairs',
        'comment' => 'Take the TV away'
      }
    end
    def valid_download(options =  {})
      {
        'title' => 'Test Download',
        'description' => 'Fake file used for testing purposes',
        'filename' => 'faketestfile.txt',
        'size' => '4222',
        'content_type' => 'application/txt',
        'is_visible' => 'true'
      }
    end
    def valid_bundle(options = {})
      {
        'name' => 'Valid Test Bundle',
        'code' => 'VTB',
        'amount' => '99.99',
        'percent' => 'false',
        'start_on' => Time.now.to_s,
        'end_on' => (Time.now + 1.year).to_s,
        'product_ids' => Product.all.collect { |product| if product.id.odd? then product.id end }.compact
      }.merge(options)
    end
    def valid_coupon(options = {})
      {
        'name' => 'Valid Test Coupon',
        'code' => 'DISCOUNT10',
        'amount' => '10.00',
        'percent' => 'false',
        'start_on' => Time.now.to_s,
        'end_on' => (Time.now + 1.year).to_s,
      }.merge(options)
    end
#    def valid_user(options = {})
#      { :name => 'Bob', :password => 'test', :password_confirmation => 'test', :email => 'foo@foo.com', :category => 'Individual' }.merge(options)
#    end
    def valid_user(options = {})
      { 'name' => 'Bob', 'password' => 'test', 'password_confirmation' => 'test', 'email' => 'foo@foo.com', 'category' => 'Individual' }.merge(options)
    end
    def valid_postal_code(options = {})
      { 'name' => '96145', 'zone_id' => '3' }
    end
    
    def gateway_response
      ActiveMerchant::Billing::Response.new(true, "Bogus Gateway: Forced success", {:authorized_amount => 0}, :test => true, :authorization => '53433' )
    end
end
