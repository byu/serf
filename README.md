serf
====

Serf is simply a Rack-like library that, when called, routes received
messages (requests or events) to "Command" handlers.

The pattern of Command objects and messaging gives us nice primatives
for Event-Driven Service Oriented Architecture in combination with
the Command Query Responsibility Separation pattern.

Philosophy
==========

The underlying idea of Serf is to define a standard Ruby code interface
that standalone gems can follow to create a business verticals services.
These gems are intended to run as standalone processes in a distributed
manner.

Fundamentally, a service creates an abstraction of:
1. Messages (with contextual headers)
2. Handlers/Commands

Messages are the representation of data, documents, etc that are
marshalled from client to service, which represents the business
level interaction of the service.

Messages may be command requests that a service must handle.
Messages may be events that a service emits.
Messages may be documents that represent state or business data.

Handlers are the code that is executed over Messages.
Handlers may process Command Messages.
Handlers may process observed Events that 3rd party services emit.

Service Libraries
=================

1. Service Libraries SHOULD implement messages as just hashes with
  defined schemas (JSON Schema).
  a. Required by all messages is the 'kind' field.
  b. By default, Serf Commands will read in hashes and turn them into
    more convenient Hashie::Mash objects.
2. Serialization of the messages SHOULD BE Json or MessagePack (I hate XML).
3. Handlers MUST implement the 'build' class method.
  a. This can just be aliased to new. But is made explicit in case we have
    custom factories.
4. Handler methods SHOULD return zero or more messages.
  a. Raised errors are caught and pushed to error channels.
  b. Returned messages MUST be Hash based objects for Serialization.
5. Handler methods SHOULD handle catch their business logic exceptions and
  return them as specialized messages that can be forwarded down error channels.
  Uncaught exceptions that are then caught by Serf are pushed as
  generic CaughtExceptionEvents, and are harder to deal with.


Example
=======

    # Require our libraries
    require 'json'
    require 'yell'

    require 'serf/builder'
    require 'serf/command'
    require 'serf/util/options_extraction'

    # create a simple logger for this example
    my_logger = Yell.new STDOUT

    # my_lib/my_policy.rb
    class MyPolicy

      def check!(headers, message)
        raise 'Policy Error: User is nil' unless headers.user
      end

      def self.build(*args, &block)
        new *args, &block
      end

    end

    # my_lib/my_overloaded_command.rb
    class MyOverloadedCommand
      include Serf::Command

      attr_reader :name
      attr_reader :do_raise

      def initialize(*args)
        extract_options! args
        @name = opts! :name
        @do_raise = opts :raises, false
      end

      def call(headers, message)
        # Just our name to sort things out

        raise "EXPECTED ERROR: Forcing Error in #{name}" if do_raise

        # Do work Here...
        # And return zero or one message as result. Nil is valid response.
        return { kind: "#{name}_result", input: message }
      end

    end

    # Create a new builder for this serf app.
    builder = Serf::Builder.new do
      # We pass in a logger to our Serf code.
      logger my_logger

      # Here, we define a route.
      # We are matching the kind for 'my_message', and we have the MyPolicy
      # to filter for this route.
      match 'my_message'
      policy MyPolicy
      run MyOverloadedCommand, name: 'my_message_command'

      match 'other_message'
      run MyOverloadedCommand, name: 'raises_error', raises: true
      run MyOverloadedCommand, name: 'good_other_handler'

      match /^events\/.*$/
      run MyOverloadedCommand, name: 'regexp_matched_command'
    end
    app = builder.to_app

    # This will submit a 'my_message' message (as a hash) to the Serf App.
    # Missing data field will raise an error within the command, which
    # will be caught by the serfer.
    my_logger.info 'Call 1: Start'
    results = app.call(nil, kind: 'my_message')
    my_logger.info "Call 1: #{results.size} #{results.to_json}"

    # Here is good result
    my_logger.info 'Call 2: Start'
    results = app.call({
        user: 'user_info_1'
      }, {
        kind: 'my_message',
        data: 'abc'
      })
    my_logger.info "Call 2: #{results.size} #{results.to_json}"

    # We should get two event messages in the results because we
    # mounted two commands to the other_message kind.
    my_logger.info 'Call 3: Start'
    results = app.call({
        user: 'user_info_1'
      }, {
        kind: 'other_message',
        data: 'abc',
      })
    my_logger.info "Call 3: #{results.size} #{results.to_json}"

    # This will match a regexp call
    my_logger.info 'Call 4: Start'
    results = app.call(
      nil,
      kind: 'events/my_event',
      data: '4')
    my_logger.info "Call 4: #{results.size} #{results.to_json}"

    begin
      # Here, we're going to submit a message that we don't handle.
      # By default, an exception will be raised.
      my_logger.info 'Call 5: Start'
      app.call(nil, kind: 'unhandled_message_kind')
      my_logger.fatal 'OOOPS: Should not get here'
    rescue => e
      my_logger.info "Call 5: Caught in main: #{e.inspect}"
    end


Contributing to serf
====================

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.


Copyright
=========

Copyright (c) 2011-2012 Benjamin Yu. See LICENSE.txt for further details.

