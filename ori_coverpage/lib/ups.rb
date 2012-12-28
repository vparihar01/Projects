require 'net/http'
require 'net/https'
require 'hpricot'
require 'ostruct'

module UPS
  class UPSError < StandardError
  end
  
  class Client
    def initialize(options)
      @prefs = options
      @logger = Rails.logger
    end
    
    def rate(to_zip, weight)
      response = self.rate_request(@prefs['origin_zip'], to_zip, weight)
      Hpricot(response).at('//ratingserviceselectionresponse/ratedshipment/transportationcharges/monetaryvalue').inner_html.to_f
    end
    
    def rate_list(to_zip, weight, cost_overrides = {})
      response = self.rate_request(@prefs['origin_zip'], to_zip, weight, true)
      Hpricot(response).search('//ratedshipment').collect do |service| 
        OpenStruct.new(
          :service_code => service.at("service/code").inner_html,
          :label => Services[service.at("service/code").inner_html],
          :cost => cost_overrides[service.at("service/code").inner_html] || service.at("transportationcharges/monetaryvalue").inner_html.to_f)
      end.sort_by(&:cost)
    end
    
    Services = {
      '01' => 'UPS Next Day Air',
      '02' => 'UPS Second Day Air',
      '03' => 'UPS Ground',
      '07' => 'UPS Worldwide Express',
      '08' => 'UPS Worldwide Expedited', 
      '11' => 'UPS Standard',
      '12' => 'UPS Three-Day Select',
      '13' => 'UPS Next Day Air Saver', 
      '14' => 'UPS Next Day Air Early A.M.',
      '54' => 'UPS Worldwide Express Plus',
      '59' => 'UPS Second Day Air A.M.',
      '65' => 'UPS Saver'      
    }
    
    protected
    
      def xml_credentials
        xml = Builder::XmlMarkup.new :indent => 2
        xml.instruct!
        xml.AccessRequest do
          xml.AccessLicenseNumber @prefs["api_key"]
          xml.UserId @prefs["login"]
          xml.Password @prefs["password"]
        end
        xml.target!
      end
    
      def send_request(url, data)
        uri = URI.parse(@prefs["url"] + '/' + url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @logger.info "Sending to UPS:\n #{xml_credentials + data}" if @prefs['debug']
        body = http.post(uri.request_uri, xml_credentials + data).body
        @logger.info "Received from UPS:\n #{body}" if @prefs['debug']
        if @error =  Hpricot(body).at('//ratingserviceselectionresponse/response/error/ErrorDescription').inner_html rescue nil
          raise UPSError, @error
        end
        body
      end
      
      def rate_request(from_zip, destination, weight, compare = false)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.instruct!
        xml.RatingServiceSelectionRequest do
          xml.Request do
            xml.TransactionReference do
              xml.CustomerContext 'Rating and Service'
              xml.XpciVersion '1.0001'
            end
            xml.RequestAction 'Rate'
            xml.RequestOption 'shop' if compare
          end
          xml.PickupType do
            xml.Code '01'
          end
          xml.Shipment do
            xml.Shipper do
              xml.Address do
                xml.PostalCode from_zip
              end
            end
            xml.ShipTo do
              xml.Address do
                if destination.is_a?(Address)
                  xml.PostalCode destination.postal_code.name
                  xml.CountryCode destination.country.iso_code_2 rescue 'US'
                  xml.City destination.city
                  xml.StateProvinceCode destination.postal_code.zone.code if destination.postal_code.zone
                else
                  xml.PostalCode destination
                end
              end
            end
            xml.Service do
              xml.Code '03'
            end
            xml.Package do
              xml.PackagingType do
                xml.Code '02'
                xml.Description 'Package'
              end
              xml.Description 'Rate Shopping'
              xml.PackageWeight do
                xml.Weight weight # in pounds
              end
            end
          end
        end
        self.send_request('Rate', xml.target!)
      end
  end
end