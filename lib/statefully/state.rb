require 'forwardable'
require 'securerandom'
require 'singleton'

# rubocop:disable Metrics/LineLength
module Statefully
  # {State} is an immutable collection of fields with some convenience methods.
  # @abstract
  class State
    include Enumerable
    extend Forwardable

    # Return the previous {State}
    #
    # @return [State]
    # @api public
    # @example
    #   Statefully::State.create.previous
    #   => #<Statefully::State::None>
    #
    #   Statefully::State.create.succeed.previous
    #   => #<Statefully::State::Success>
    attr_reader :previous

    # @!method each
    #   @return [Enumerator]
    #   @see https://docs.ruby-lang.org/en/2.0.0/Hash.html#method-i-each Hash#each
    #   @api public
    #   @example
    #     Statefully::State.create(key: 'val').each { |key, val| puts("#{key} => #{val}") }
    #     key => val
    # @!method fetch
    #   @return [Object]
    #   @see https://docs.ruby-lang.org/en/2.0.0/Hash.html#method-i-fetch Hash#fetch
    #   @api public
    #   @example
    #     Statefully::State.create(key: 'val').fetch(:key)
    #     => 'val'
    # @!method key?
    #   @return [Boolean]
    #   @see https://docs.ruby-lang.org/en/2.0.0/Hash.html#method-i-key-3F Hash#key?
    #   @api public
    #   @example
    #     state = Statefully::State.create(key: 'val')
    #     state.key?(:key)
    #     => true
    #     state.key?(:other)
    #     => false
    # @!method keys
    #   @return [Array<Symbol>]
    #   @see https://docs.ruby-lang.org/en/2.0.0/Hash.html#method-i-keys Hash#keys
    #   @api public
    #   @example
    #     Statefully::State.create(key: 'val').keys
    #     => [:key]
    def_delegators :@_members, :each, :fetch, :key?, :keys

    # Create an instance of {State} object
    #
    # This is meant as the only valid way of creating {State} objects.
    #
    # @param values [Hash<Symbol, Object>] keyword arguments
    #
    # @return [type] [description]
    # @api public
    # @example
    #   Statefully::State.create(key: 'val')
    #   => #<Statefully::State::Success key="val">
    def self.create(**values)
      base = { correlation_id: SecureRandom.uuid }
      Success.send(:new, base.merge(values), previous: None.instance).freeze
    end

    # Return a {Diff} between current and previous {State}
    #
    # @return [Diff]
    # @api public
    # @example
    #  Statefully::State.create.succeed(key: 'val').diff
    #  => #<Statefully::Diff::Changed added={key: "val"}>
    def diff
      Diff.create(current: self, previous: previous)
    end

    # Return all historical changes to this {State}
    #
    # @return [Array<Diff>]
    # @api public
    # @example
    #   Statefully::State.create.succeed(key: 'val').history
    #   => [#<Statefully::Diff::Changed added={key: "val"}>, #<Statefully::Diff::Created>]
    def history
      ([diff] + previous.history).freeze
    end

    # Check if the current {State} is successful
    #
    # @return [Boolean]
    # @api public
    # @example
    #   state = Statefully::State.create
    #   state.successful?
    #   => true
    #
    #   state.fail(RuntimeError.new('Boom!')).successful?
    #   => false
    def successful?
      true
    end

    # Check if the current {State} is failed
    #
    # @return [Boolean]
    # @api public
    # @example
    #   state = Statefully::State.create
    #   state.failed?
    #   => false
    #
    #   state.fail(RuntimeError.new('Boom!')).failed?
    #   => true
    def failed?
      !successful?
    end

    # Check if the current {State} is finished
    #
    # @return [Boolean]
    # @api public
    # @example
    #   state = Statefully::State.create
    #   state.finished?
    #   => false
    #
    #   state.finish.finished?
    #   => true
    def finished?
      false
    end

    # Check if the current {State} is none (a null-object of {State})
    #
    # @return [Boolean]
    # @api public
    # @example
    #   state = Statefully::State.create
    #   state.none?
    #   => false
    #
    #   state.previous.none?
    #   => true
    def none?
      false
    end

    # Resolve the current {State}
    #
    # Resolving will return the current {State} if successful, but raise an
    # error wrapped in a {State::Failure}. This is a convenience method inspired
    # by monadic composition from functional languages.
    #
    # @return [State] if the receiver is {#successful?}
    # @raise [StandardError] if the receiver is {#failed?}
    # @api public
    # @example
    #   Statefully::State.create(key: 'val').resolve
    #   => #<Statefully::State::Success key="val">
    #
    #   Statefully::State.create.fail(RuntimeError.new('Boom!')).resolve
    #   RuntimeError: Boom!
    #           [STACK TRACE]
    def resolve
      self
    end

    # Show the current {State} in a human-readable form
    #
    # @return [String]
    # @api public
    # @example
    #   Statefully::State.create(key: 'val')
    #   => #<Statefully::State::Success key="val">
    def inspect
      _inspect_details({})
    end

    private

    # State fields
    #
    # @return [Hash]
    # @api private
    attr_reader :_members

    # Constructor for the {State} object
    #
    # @param values [Hash<Symbol, Object>] values to store
    # @param previous [State] previous {State}
    #
    # @return [State]
    # @api private
    def initialize(values, previous:)
      @_members = values.freeze
      @previous = previous
    end
    private_class_method :new

    # Inspect {State} fields, with extras
    #
    # @param extras [Hash] Non-member values to include
    #
    # @return [String]
    # @api private
    def _inspect_details(extras)
      details = [self.class.name]
      fields = _members.merge(extras)
      details << Inspect.from_fields(fields) unless fields.empty?
      "#<#{details.join(' ')}>"
    end

    # Dynamically pass unknown messages to the underlying state storage
    #
    # State fields become accessible through readers, like in an
    # {http://ruby-doc.org/stdlib-2.0.0/libdoc/ostruct/rdoc/OpenStruct.html OpenStruct}.
    # A single state field can be questioned for existence by having its name
    # followed by a question mark - eg. bacon?.
    # A single state field can be force-accessed by having its name followed by
    # an exclamation mark - eg. bacon!.
    #
    # This method reeks of :reek:TooManyStatements.
    #
    # @param name [Symbol|String]
    # @param args [Array<Object>]
    # @param block [Proc]
    #
    # @return [Object]
    # @raise [NoMethodError]
    # @raise [Errors::StateMissing]
    # @api private
    # @example
    #   state = Statefully::State.create(bacon: 'tasty')
    #
    #   state.bacon
    #   => "tasty"
    #
    #   state.bacon?
    #   => true
    #
    #   state.bacon!
    #   => "tasty"
    #
    #   state.cabbage
    #   NoMethodError: undefined method `cabbage' for #<Statefully::State::Success bacon="tasty">
    #           [STACK TRACE]
    #
    #   state.cabbage?
    #   => false
    #
    #   state.cabbage!
    #   Statefully::Errors::StateMissing: field 'cabbage' missing from state
    #           [STACK TRACE]
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
      raise Errors::StateMissing, base
    end

    # Companion to `method_missing`
    #
    # This method reeks of :reek:BooleanParameter.
    #
    # @param name [Symbol|String]
    # @param _include_private [Boolean]
    #
    # @return [Boolean]
    # @api private
    def respond_to_missing?(name, _include_private = false)
      str_name = name.to_s
      key?(name.to_sym) || %w[? !].any?(&str_name.method(:end_with?)) || super
    end

    # {None} is a null-value of {State}
    class None < State
      include Singleton

      # Return all historical changes to this {State}
      #
      # @return [Array<Diff>]
      # @api public
      # @example
      #   Statefully::State.create.succeed(key: 'val').history
      #   => [#<Statefully::Diff::Changed added={key: "val"}>, #<Statefully::Diff::Created>]
      def history
        []
      end

      # Check if the current {State} is none (a null-object of {State})
      #
      # @return [Boolean]
      # @api public
      # @example
      #   state = Statefully::State.create
      #   state.none?
      #   => false
      #
      #   state.previous.none?
      #   => true
      def none?
        true
      end

      private

      # Constructor for the {None} object
      # @api private
      def initialize
        @_members = {}.freeze
        @previous = self
      end
    end

    # {Success} is a not-yet failed {State}.
    class Success < State
      # Return the next, successful {State} with new values merged in (if any)
      #
      # @param values [Hash<Symbol, Object>] New values of the {State}
      #
      # @return [State::Success] new successful {State}
      # @api public
      # @example
      #   Statefully::State.create.succeed(key: 'val')
      #   => #<Statefully::State::Success key="val">
      def succeed(**values)
        self.class.send(:new, _members.merge(values).freeze, previous: self)
      end

      # Return the next, failed {State} with a stored error
      #
      # @param error [StandardError] error to store
      #
      # @return [State::Failure] new failed {State}
      # @api public
      # @example
      #   Statefully::State.create(key: 'val').fail(RuntimeError.new('Boom!'))
      #   => #<Statefully::State::Failure key="val", error="#<RuntimeError: Boom!>">
      def fail(error)
        Failure.send(:new, _members, error, previous: self).freeze
      end

      # Return the next, finished? {State}
      #
      # @return [State::State] new finished {State}
      # @api public
      # @example
      #   Statefully::State.create(key: 'val').finish
      #   => #<Statefully::State::Finished key="val">
      def finish
        Finished.send(:new, _members, previous: self).freeze
      end
    end

    # {Failure} is a failed {State}.
    class Failure < State
      # Error stored in the current {State}
      #
      # @return [StandardError]
      # @api public
      # @example
      #   state = Statefully::State.create(key: 'val').fail(RuntimeError.new('Boom!'))
      #   state.error
      #   => #<RuntimeError: Boom!>
      attr_reader :error

      # Constructor for the {Failure} object
      #
      # @param values [Hash<Symbol, Object>] fields to be stored
      # @param error [StandardError] error to be wrapped
      # @param previous [State] previous state
      # @api private
      def initialize(values, error, previous:)
        super(values, previous: previous)
        @error = error
      end

      # Return a {Diff} between current and previous {State}
      #
      # @return [Diff::Failed]
      # @api public
      # @example
      #   state = Statefully::State.create(key: 'val').fail(RuntimeError.new('Boom!'))
      #   state.diff
      #   => #<Statefully::Diff::Failed error=#<RuntimeError: Boom!>>
      def diff
        Diff::Failed.new(error).freeze
      end

      # Check if the current {State} is successful
      #
      # @return [Boolean]
      # @api public
      # @example
      #   state = Statefully::State.create
      #   state.successful?
      #   => true
      #
      #   state.fail(RuntimeError.new('Boom!')).successful?
      #   => false
      def successful?
        false
      end

      # Resolve the current {State}
      #
      # Resolving will return the current {State} if successful, but raise an
      # error wrapped in a {State::Failure}. This is a convenience method inspired
      # by monadic composition from functional languages.
      #
      # @return [State] if the receiver is {#successful?}
      # @raise [StandardError] if the receiver is {#failed?}
      # @api public
      # @example
      #   Statefully::State.create(key: 'val').resolve
      #   => #<Statefully::State::Success key="val">
      #
      #   Statefully::State.create.fail(RuntimeError.new('Boom!')).resolve
      #   RuntimeError: Boom!
      #           [STACK TRACE]
      def resolve
        raise error
      end

      # Show the current {State} in a human-readable form
      #
      # @return [String]
      # @api public
      # @example
      #   Statefully::State.create.fail(RuntimeError.new('Boom!'))
      #   => #<Statefully::State::Failure error="#<RuntimeError: Boom!>">
      def inspect
        _inspect_details(error: error.inspect)
      end
    end

    # {Finished} state is a state which is successful, but should not be
    # processed any further. This could be useful for things like early returns.
    class Finished < State
      # Return a {Diff} between current and previous {State}
      #
      # This method reeks of :reek:UtilityFunction - just implementing an API.
      #
      # @return [Diff::Finished]
      # @api public
      # @example
      #   Statefully::State.create(key: 'val').finish.diff
      #   => #<Statefully::Diff::Finished>
      def diff
        Diff::Finished.instance
      end

      # Check if the current {State} is finished
      #
      # @return [Boolean]
      # @api public
      # @example
      #   state = Statefully::State.create
      #   state.finished?
      #   => false
      #
      #   state.finish.finished?
      #   => true
      def finished?
        true
      end
    end
  end
end
# rubocop:enable Metrics/LineLength
