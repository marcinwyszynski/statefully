module Statefully
  # {Inspect} provides helpers for human-readable object inspection.
  module Inspect
    # Inspect a [Hash] of values in `key: val` format
    # @param input [Hash] input values
    #
    # @return [String]
    # @api private
    def from_hash(input)
      '{' + input.map { |key, val| "#{key}: #{val.inspect}" }.join(', ') + '}'
    end
    module_function :from_hash

    # Inspect a [Hash] of values in `key=val` format
    # @param input [Hash] input values
    #
    # @return [String]
    # @api private
    def from_fields(input)
      input.map { |key, val| "#{key}=#{val.inspect}" }.join(', ')
    end
    module_function :from_fields
  end
  private_constant :Inspect
end
