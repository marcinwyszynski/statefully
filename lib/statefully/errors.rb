# rubocop:disable Metrics/LineLength
module Statefully
  module Errors
    # StateMissing represents an error being thrown when a member of {State} is
    # being accessed using an unsafe accessor (eg. #member!). It is technically
    # a NoMethodError, but it is introduced to allow users to differentiate
    # between failing state accessors and other code that may fail in a similar
    # way.
    class StateMissing < ::RuntimeError
      # Stores the name of the missing {State} field
      #
      # @return [Symbol] the name of the field.
      # @api public
      # @example
      #   Statefully::Errors::StateMissing.new(:bacon).field
      #   => :bacon
      attr_reader :field

      # Error constructor for {StateMissing}
      #
      # @param field [Symbol] name of the missing field.
      # @api public
      # @example
      #   Statefully::Errors::StateMissing.new(:bacon)
      #   => #<Statefully::Errors::StateMissing: field 'bacon' missing from state>
      def initialize(field)
        @field = field
        super("field '#{field}' missing from state")
      end
    end # class StateMissing
  end # module Errors
end # module Statefully
