require 'set'
require 'singleton'

module Statefully
  # {Diff} is a difference between two neighboring instances of {State}.
  #
  # @abstract
  class Diff
    # Create is the only public interface to the Diff class
    #
    # @param current [Statefully::State] current state
    # @param previous [Statefully::State] previous state
    #
    # @return [Statefully::Diff] Difference between states.
    # @api public
    # @example
    #   previous = Statefully::State.create
    #   current = previus.succeed(key: 'val')
    #   Statefully::Diff.create(current, previous)
    #   => #<Statefully::Diff::Changed added={key: "val"}>
    #
    # This method reeks of :reek:FeatureEnvy (of current).
    def self.create(current:, previous:)
      return current.diff if current.failed? || current.finished?
      changes = Builder.new(current: current, previous: previous).build
      return Created.new(**changes).freeze if previous.none?
      changes.empty? ? Unchanged.instance : Changed.new(**changes).freeze
    end

    # Check if a {Diff} is empty
    #
    # An empty {Diff} means that is there are no changes in properties between
    # current and previous {State}.
    #
    # @return [Boolean]
    # @api public
    # @example
    #   Statefully::Diff::Unchanged.instance.empty?
    #   => true
    def empty?
      true
    end

    # Hash of added properties and their values
    #
    # @return [Hash<Symbol, Object>]
    # @api public
    # @example
    #   Statefully::Diff::Unchanged.instance.added
    #   => {}
    def added
      {}
    end

    # Hash of changed properties and their current and previous values
    #
    # @return [Hash<Symbol, Statefully::Change>]
    # @api public
    # @example
    #   Statefully::Diff::Unchanged.instance.added.changed
    #   => {}
    def changed
      {}
    end

    # Check if a key has been added
    #
    # @param key [Symbol]
    # @return [Boolean]
    # @api public
    # @example
    #   diff = Statefully::Diff::Changed.new(added: {key: 7})
    #   diff.added?(:key)
    #   => true
    #   diff.added?(:other)
    #   => false
    def added?(key)
      added.key?(key)
    end

    # Check if a key has been changed
    #
    # @param key [Symbol]
    # @return [Boolean]
    # @api public
    # @example
    #   diff = Statefully::Diff::Changed.new(
    #     changed: {key: Statefully::Change.new(current: 7, previous: 8)},
    #   )
    #   diff.changed?(:key)
    #   => true
    #   diff.changed?(:other)
    #   => false
    def changed?(key)
      changed.key?(key)
    end

    # {Changed} is a {Diff} which contains changes between two successful
    # {State}s.
    class Changed < Diff
      # Hash of added properties and their values
      #
      # @return [Hash<Symbol, Object>]
      # @api public
      # @example
      #   Statefully::Diff::Changed.new(added: {key: 7}).added
      #   => {:key => 7}
      attr_reader :added

      # Hash of changed properties and their current and previous values
      #
      # @return [Hash<Symbol, Change>]
      # @api public
      # @example
      #   Statefully::Diff::Changed.new(
      #     changed: {key: Statefully::Change.new(current: 7, previous: 8)},
      #   )
      #   => {:key=>#<Statefully::Change current=7, previous=8>}
      attr_reader :changed

      # Constructor for {Diff::Changed}
      #
      # @param added [Hash<Symbol, Object>] added fields
      # @param changed [Hash<Symbol, Change>] [changed fields]
      # @api public
      # @example
      #   Statefully::Diff::Changed.new(added: {key: 7})
      #   => #<Statefully::Diff::Changed added={key: 7}>
      def initialize(added: {}, changed: {})
        @added = added.freeze
        @changed = changed.freeze
      end

      # Check if a {Diff} resulted from creating a {State}
      #
      # @return [Boolean]
      # @api public
      # @example
      #   Stateful::State.created.created?
      #   => true
      #
      #   Stateful::State.created.succeed.created?
      #   => false
      def created?
        false
      end

      # Check if a {Diff} is empty
      #
      # An empty {Diff} means that there are no changes in properties between
      # current and previous {State}.
      #
      # @return [Boolean]
      # @api public
      # @example
      #   Statefully::Diff::Changed.new(added: {key: 7}).empty?
      #   => false
      def empty?
        added.empty? && changed.empty?
      end

      # Human-readable representation of the {Change} for console inspection
      #
      # @return [String]
      # @api semipublic
      # @example
      #   Statefully::Diff::Changed.new(added: {key: 7})
      #   => #<Statefully::Diff::Changed added={key: 7}>
      def inspect
        details = [self.class.name]
        details << inspect_details unless empty?
        "#<#{details.join(' ')}>"
      end

      private

      # Helper method to print out added and changed fields
      # @return [String]
      # @api private
      def inspect_details
        [inspect_added, inspect_changed].compact.join(', ')
      end

      # Helper method to print out added fields
      # @return [String]
      # @api private
      def inspect_added
        added.empty? ? nil : "added=#{Inspect.from_hash(added)}"
      end

      # Helper method to print out changed fields
      # @return [String]
      # @api private
      def inspect_changed
        changed.empty? ? nil : "changed=#{Inspect.from_hash(changed)}"
      end
    end # class Changed

    module SingletonInspect
      # Human-readable representation of the {Diff} singleton
      #
      # @return [String]
      # @api private
      def inspect
        "#<#{self.class.name}>"
      end
    end # module SingletonInspect
    private_constant :SingletonInspect

    # {Created} represents a difference between a null and non-null {State}.
    class Created < Changed
      # Check if a {Diff} resulted from creating a {State}
      #
      # @return [Boolean]
      # @api public
      # @example
      #   Stateful::State.created.created?
      #   => true
      #
      #   Stateful::State.created.succeed.created?
      #   => false
      def created?
        true
      end
    end # class Created

    # {Unchanged} represents a lack of difference between two {State}s.
    class Unchanged < Diff
      include Singleton
      include SingletonInspect
    end # class Unchanged

    # {Failed} represents a difference between a succesful and failed {State}.
    class Failed < Diff
      # Error that caused the {State} to fail
      #
      # @return [StandardError]
      # @api public
      # @example
      #   Statefully::Diff::Failed.new(RuntimeError.new('Boom!')).error
      #   => #<RuntimeError: Boom!>
      attr_reader :error

      # Constructor for {Diff::Failed}
      #
      # @param error [StandardError] error that caused the {State} to fail
      # @api semipublic
      # @example
      #   Statefully::Diff::Failed.new(RuntimeError.new('Boom!'))
      #   => #<Statefully::Diff::Failed error=#<RuntimeError: Boom!>>
      def initialize(error)
        @error = error
      end

      # Human-readable representation of the {Diff::Failed}
      #
      # @return [String]
      # @api semipublic
      # @example
      #   Statefully::Diff::Failed.new(RuntimeError.new('Boom!'))
      #   => #<Statefully::Diff::Failed error=#<RuntimeError: Boom!>>
      def inspect
        "#<#{self.class.name} error=#{error.inspect}>"
      end
    end # class Failed

    # {Failed} represents a difference between a succesful and finished {State}.
    class Finished < Diff
      include Singleton
      include SingletonInspect
    end # class Finished

    class Builder
      # Constructor for the {Builder} object
      #
      # @param current [State] current {State}
      # @param previous [State] previous {State}
      # @api private
      def initialize(current:, previous:)
        @current = current
        @previous = previous
      end

      # Build a Hash of added and changed {State} fields
      #
      # @return [Hash]
      # @api private
      def build
        empty? ? {} : { added: added, changed: changed }
      end

      private

      # List added fields
      #
      # @return [Hash]
      # @api private
      def added
        @added ||=
          (current_keys - previous_keys)
          .map { |key| [key, @current.fetch(key)] }
          .to_h
      end

      # List changed fields
      #
      # @return [Hash]
      # @api private
      def changed
        @changed ||=
          (current_keys & previous_keys)
          .map { |key| [key, change_for(key)] }
          .to_h
          .reject { |_, val| val.none? }
      end

      # Change for individual key
      #
      # @param [Symbol] key name
      #
      # @return [Change]
      # @api private
      def change_for(key)
        Change.new(
          current: @current.fetch(key),
          previous: @previous.fetch(key),
        ).freeze
      end

      # Check if the nothing has changed
      #
      # @return [Boolean]
      # @api private
      def empty?
        added.empty? && changed.empty?
      end

      # Return the set of keys for the current {State}
      #
      # @return [Set<Symbol>]
      # @api private
      def current_keys
        Set.new(@current.keys)
      end

      # Return the set of keys for previous {State}
      #
      # @return [Set<Symbol>]
      # @api private
      def previous_keys
        Set.new(@previous.keys)
      end
    end # class Builder
    private_constant :Builder
  end # class Diff
end # module Statefully
