module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # == Description
    # This bank account object can be used as a stand alone object. It acts just like an ActiveRecord object
    # but doesn't support the .save method as its not backed by a database.
    # 
    # For testing purposes, use the 'bogus' bank account type. This account skips the vast majority of 
    # validations. This allows you to focus on your core concerns until you're ready to be more concerned 
    # with the details of particular creditcards or your gateway.
    # 
    # == Testing With BankAccount
    # Often when testing we don't care about the particulars of a given card type. When using the 'test' 
    # mode in your Gateway, there are six different valid bank account numbers: 1, 2, 3, 'success', 'fail', 
    # and 'error'.
    # 
    #--
    # For details, see BankAccountMethods#valid_account?
    #++
    #
    # == Example Usage
    # ba = BankAccount.new(
    #   :first_name     => 'Steve',
    #   :last_name      => 'Smith',
    #   :type           => 'checking',
    #   :bank_name      => 'Bank of America',
    #   :echeck_type    => 'ccd',
    #   :routing_number => '123456789',
    #   :account_number => '111000025'
    #
    #   ba.valid? # => true
    #   ba.display_number # => XXXX5678
    # 
    class BankAccount
      include Validateable
      
      ## Attributes
      
      # Essential attributes for a valid, non-bogus bank account
      attr_accessor :account_number, :routing_number, :first_name, :last_name, :type, :echeck_type
      
      # Additional optional attributes
      attr_accessor :bank_name
      
      def name?
        first_name? && last_name?
      end
      
      def first_name?
        !@first_name.blank?
      end
      
      def last_name?
        !@last_name.blank?
      end
            
      def name
        "#{@first_name} #{@last_name}"
      end
            
      def account_number?
        !account_number.blank?
      end
      
      def routing_number?
        !routing_number.blank?
      end

      # Show the account number, with all but last 4 numbers replaced with "X". (XXXX4338)
      def display_number
        # 
        ('X' * (account_number.to_s.length - last_digits.size)) + last_digits
        # account_number.to_s[0..last_digits.size].to_s.size + 
        # last_digits.to_s
      end
      
      def last_digits
        account_number.to_s.length <= 4 ? account_number.to_s : account_number.to_s.slice(-4..-1)
      end
      
      def validate
        validate_essential_attributes

        # Bogus account is pretty much for testing purposes. Lets just skip these extra tests if its used
        return if type == 'bogus'

        validate_account_type
        validate_routing_number
        validate_echeck_type
      end
      
      private
      
      def before_validate #:nodoc: 
        self.account_number = account_number.to_s.gsub(/[^\d]/, "")
        self.routing_number = routing_number.to_s.gsub(/[^\d]/, "")
        self.type.downcase! if type.respond_to?(:downcase)
        self.type = "checking" if type.blank?
      end
      
      def validate_essential_attributes #:nodoc:
        errors.add :first_name,     "cannot be empty"  if @first_name.blank?
        errors.add :last_name,      "cannot be empty"  if @last_name.blank?
        errors.add :account_number, "cannot be empty"  if @account_number.blank?
      end      
      
      def validate_account_type #:nodoc:
        errors.add :type, "is invalid" unless ["checking","bogus","savings","business_checking"].include?(type)
      end
      
      def validate_routing_number #:nodoc:
        errors.add :routing_number, "cannot be empty"  if @routing_number.blank?
        errors.add :routing_number, "should be 9 digits" if @routing_number.to_s.length != 9
        errors.add :routing_number, "is invalid" unless valid_routing_number?
      end
      
      def validate_echeck_type #:nodoc:
        errors.add :echeck_type, "is invalid" unless ['ccd','ppd'].include?(echeck_type)
      end

      # Routing numbers may be validated by calculating a checksum and dividing it by 10. The
      # formula is:
      #   (3(d1 + d4 + d7) + 7(d2 + d5 + d8) + 1(d3 + d6 + d9))mod 10 = 0
      # See http://en.wikipedia.org/wiki/Routing_transit_number#Internal_checksums
      def valid_routing_number?
        d = routing_number.to_s.split('').map(&:to_i).select { |d| (0..9).include?(d) }
        case d.size
          when 9 then
            checksum = ((3 * (d[0] + d[3] + d[6])) +
                        (7 * (d[1] + d[4] + d[7])) +
                             (d[2] + d[5] + d[8])) % 10
            case checksum
              when 0 then true
              else        false
            end
          else false
        end
      end

    end
  end
end
