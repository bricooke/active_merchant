require File.dirname(__FILE__) + '/../test_helper'

class BankAccountTest < Test::Unit::TestCase
  def setup
    @checking = bank_account(:account_number => '123456', :routing_number => '111000025', :type => 'checking')
    @savings  = bank_account(:account_number => '123456', :routing_number => '111000025', :type => 'savings')
  end
  
  def test_constructor_should_properly_assign_values
    b = bank_account
  
    assert_equal "11223344", b.account_number
    assert_equal "111000025", b.routing_number
    assert_equal "Josh Martin", b.name
    assert_equal "checking", b.type
    assert_valid b
  end
  
  def test_new_bank_account_should_not_be_valid
    b = BankAccount.new
  
    assert_not_valid b
    assert_false     b.errors.empty?
  end

  def test_should_be_a_valid_checking_account
    assert_valid @checking
    assert       @checking.errors.empty?
  end
  
  def test_should_be_a_valid_savings_account
    assert_valid @savings
    assert       @savings.errors.empty?
  end
  
  def test_accounts_with_empty_names_should_not_be_valid
    @checking.first_name = ''
    @checking.last_name  = '' 
    
    assert_not_valid @checking
    assert_false     @checking.errors.empty?
  end
  
  def test_should_be_able_to_access_errors_indifferently
    @checking.first_name = ''
    
    assert_not_valid @checking
    assert @checking.errors.on(:first_name)
    assert @checking.errors.on("first_name")
  end

  def test_should_be_able_to_liberate_a_bogus_account
    b = bank_account(:routing_number => '', :type => 'bogus')
    assert_valid b
    
    b.type = 'checking'
    assert_not_valid b
  end

  def test_should_be_able_to_identify_invalid_routing_numbers
    @checking.routing_number = nil
    assert_not_valid @checking
    
    @checking.routing_number = "1234567ff"
    assert_not_valid @checking
    assert_false @checking.errors.on(:type)
    assert       @checking.errors.on(:routing_number)

    @checking.routing_number = "1"
    assert_not_valid @checking
    assert_false @checking.errors.on(:type)
    assert       @checking.errors.on(:routing_number)

    @checking.routing_number = "1234567890111"
    assert_not_valid @checking
    assert_false @checking.errors.on(:type)
    assert       @checking.errors.on(:routing_number)

    @checking.routing_number = "abcdefghi"
    assert_not_valid @checking
    assert_false @checking.errors.on(:type)
    assert       @checking.errors.on(:routing_number)  
  end
  
  def test_should_be_a_valid_routing_number
    @checking.routing_number = "111000025"
    
    assert_valid @checking
  end

  def test_should_not_be_valid_with_invalid_type
    b = bank_account(:type => 'invalid')
    assert_not_valid b
  end

  def test_should_display_number
    assert_equal 'XXXXXXXXXXXX1234', BankAccount.new(:account_number => '1111222233331234').display_number
    assert_equal 'XXXXXXXXXXX1234',  BankAccount.new(:account_number => '111222233331234').display_number
    assert_equal 'XXXXXXXXXX1234',   BankAccount.new(:account_number => '11122233331234').display_number

    assert_equal '',      BankAccount.new(:account_number => nil).display_number
    assert_equal '123',   BankAccount.new(:account_number => '123').display_number
    assert_equal 'X2345', BankAccount.new(:account_number => '12345').display_number
    assert_equal '1234',  BankAccount.new(:account_number => '1234').display_number
  end

  def test_should_return_last_four_digits_of_card_number
    b = BankAccount.new(:account_number => "4779139500118580")
    assert_equal "8580", b.last_digits
  end

  def test_bogus_last_digits
    b = BankAccount.new(:account_number => "1")
    assert_equal "1", b.last_digits
  end

  def test_should_be_true_when_bank_account_has_a_first_name
    c = BankAccount.new
    assert_false c.first_name?
    
    c = BankAccount.new(:first_name => 'James')
    assert c.first_name?
  end
  
  def test_should_be_true_when_bank_account_has_a_last_name
    c = BankAccount.new
    assert_false c.last_name?
    
    c = BankAccount.new(:last_name => 'Herdman')
    assert c.last_name?
  end
  
  def test_should_test_for_a_full_name
    c = BankAccount.new
    assert_false c.name?
  
    c = BankAccount.new(:first_name => 'James', :last_name => 'Herdman')
    assert c.name?
  end
  
  # The following is a regression for a bug that raised an exception when
  # a new credit card was validated
  def test_validate_new_card
    bank_account = BankAccount.new
    
    assert_nothing_raised do
      bank_account.validate
    end
  end
  
  def test_validating_bogus_card
    bank_account = bank_account(:account_number => '1', :type => nil)
    assert bank_account.valid?
  end
  
  def test_strip_non_digit_characters
    b = bank_account(:account_number => '4242-4242      %%%%%%4242......4242',
                     :routing_number => '11100 %% WOO BLAH @#$@ 0025')
    assert b.valid?
    assert_equal "4242424242424242", b.account_number
    assert_equal "111000025", b.routing_number
  end

  def test_before_validate_handles_blank_number
    b = bank_account(:account_number => nil)
    assert !b.valid?
    assert_equal "", b.account_number
  end
  
end
