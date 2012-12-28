require File.dirname(__FILE__) + '/../test_helper'

class ContractTest < ActiveSupport::TestCase
  fixtures :contracts, :sales_teams, :sales_zones
  
  test "should_create_valid_contract" do
    @contract = Contract.new(valid_contract)
    assert @contract.save
  end

  test "should_not_create_another_contract_in_sales_zone_when_first_covers_all" do
    @contract = Contract.new(valid_contract(:sales_zone => sales_zones(:new_jersey)))
    assert !@contract.save
    assert_equal "Cannot create a contract for this sales zone with the category of 'All' since other contracts already exist for this sales zone", @contract.errors.full_messages.first
    @contract.category = 'School'
    assert !@contract.save
    assert_equal "Another contract for this zone covers the same category (or has the category of 'All')", @contract.errors.full_messages.first
  end
  
  test "should_not_create_contract_that_duplicates_category" do
    contracts(:don_new_jersey).update_attribute(:category, 'School')
    @contract = Contract.new(valid_contract(
      :sales_zone => sales_zones(:new_jersey), :category => 'School'))
    assert !@contract.save
    assert_equal "Another contract for this zone covers the same category (or has the category of 'All')", @contract.errors.full_messages.first
  end
  
  test "should_not_create_contract_covering_all_with_other_contracts_in_zone" do
    contracts(:don_new_jersey).update_attribute(:category, 'School')
    @contract = Contract.new(valid_contract(
      :sales_zone => sales_zones(:new_jersey), :category => 'All'))
    assert !@contract.save
    assert_equal "Cannot create a contract for this sales zone with the category of 'All' since other contracts already exist for this sales zone", @contract.errors.full_messages.first
  end
  
end
