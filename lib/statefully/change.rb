module Statefully
  # Change is a tuple of current and previous value of a field in a {Diff}.
  class Change
    # Returns the current {State} field value
    #
    # @return [Object] current {State} field value
    # @api public
    # @example
    #   Statefully::Change.new(current: 7, previous: 8).current
    #   => 7
    attr_reader :current

    # Returns the previous {State} field value
    #
    # @return [Object] previous {State} field value
    # @api public
    # @example
    #   Statefully::Change.new(current: 7, previous: 8).previous
    #   => 8
    attr_reader :previous

    # Constructor for the {Change} object
    # @param current [Object] current {State} field value
    # @param previous [Object] previous {State} field value
    # @api public
    # @example
    #   Statefully::Change.new(current: 7, previous: 8)
    #   => #<Statefully::Change current=7, previous=8>
    def initialize(current:, previous:)
      @current = current
      @previous = previous
    end

    # Internal-only method used to determine whether there was any change
    # @api private
    def none?
      @current == @previous
    end

    # Human-readable representation of the {Change} for console inspection
    #
    # @return [String]
    # @api semipublic
    # @example
    #   Statefully::Change.new(current: 7, previous: 8)
    #   => #<Statefully::Change current=7, previous=8>
    def inspect
      "#<#{self.class.name} " \
      "#{Inspect.from_fields(current: current, previous: previous)}>"
    end
  end
end
