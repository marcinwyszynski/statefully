require 'forwardable'
require 'singleton'

module Statefully
  class State
    include Enumerable
    extend Forwardable

    attr_reader :previous
    def_delegators :@_members, :each, :key?, :keys, :fetch

    def self.create(**values)
      Success.send(:new, values, previous: None.instance).freeze
    end

    def diff
      Diff.create(self, previous)
    end

    def history
      ([diff] + previous.history).freeze
    end

    def success?
      true
    end

    def failure?
      !success?
    end

    def finished?
      false
    end

    def resolve
      self
    end

    def inspect
      _inspect_details({})
    end

    private

    attr_reader :_members

    def initialize(values, previous:)
      @_members = values.freeze
      @previous = previous
    end
    private_class_method :new

    def _inspect_details(extras)
      details = [self.class.name]
      fields = _members.merge(extras)
      details << Inspect.from_fields(fields) unless fields.empty?
      "#<#{details.join(' ')}>"
    end

    # This method reeks of :reek:TooManyStatements.
    def method_missing(name, *args, &block)
      sym_name = name.to_sym
      return fetch(sym_name) if key?(sym_name)
      str_name = name.to_s
      modifier = str_name[-1]
      return super unless %w[? !].include?(modifier)
      base = str_name[0...-1].to_sym
      known = key?(base)
      return known if modifier == '?'
      return fetch(base) if known
      raise Missing, base
    end

    # This method reeks of :reek:BooleanParameter.
    def respond_to_missing?(name, _include_private = false)
      str_name = name.to_s
      key?(name.to_sym) || %w[? !].any?(&str_name.method(:end_with?)) || super
    end

    class Missing < RuntimeError
      attr_reader :field

      def initialize(field)
        @field = field
        super("field '#{field}' missing from state")
      end
    end # class Missing

    class None < State
      include Singleton

      def history
        []
      end

      private

      def initialize
        @_members = {}.freeze
        @previous = self
      end
    end # class None
    private_constant :None

    # Success is a not-yet failed State.
    class Success < State
      def succeed(**values)
        self.class.send(:new, _members.merge(values).freeze, previous: self)
      end

      def fail(error)
        Failure.send(:new, _members, error, previous: self).freeze
      end

      def finish
        Finished.send(:new, _members, previous: self).freeze
      end
    end # class Success
    private_constant :Success

    # Failure is a failed State.
    class Failure < State
      attr_reader :error

      def initialize(values, error, previous:)
        super(values, previous: previous)
        @error = error
      end

      def diff
        error
      end

      def success?
        false
      end

      def resolve
        raise error
      end

      def inspect
        _inspect_details(error: error.inspect)
      end
    end # class Failure
    private_constant :Failure

    class Finished < State
      def diff
        :finished
      end

      def finished?
        true
      end
    end # class Finished
    private_constant :Finished

    module Inspect
      def from_fields(input)
        input.map { |key, val| "#{key}=#{val.inspect}" }.join(', ')
      end
      module_function :from_fields
    end # module Inspect
    private_constant :Inspect
  end # class State
end # module Statefully
