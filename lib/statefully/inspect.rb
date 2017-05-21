module Statefully
  module Inspect
    def from_hash(input)
      '{' + input.map { |key, val| "#{key}: #{val.inspect}" }.join(', ') + '}'
    end
    module_function :from_hash

    def from_fields(input)
      input.map { |key, val| "#{key}=#{val.inspect}" }.join(', ')
    end
    module_function :from_fields
  end # module Inspect
  private_constant :Inspect
end # module Statefully
