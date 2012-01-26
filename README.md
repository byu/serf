serf
====

Serf is a library that scaffolds distributed systems that are architected using
Event-Driven Service Oriented Architecture design in combinations with
the Command Query Responsibility Separation pattern.

Philosophy
==========

The underlying idea of Serf is to define a standard Ruby code interface
that standalone gems can follow to create a business verticals services.
These gems are intended to run as standalone processes in a distributed
manner.

Fundamentally, a service creates an abstraction of:
1. Messages
2. Handlers

Messages are the representation of data, documents, etc that are
marshalled from client to service, which represents the business
level interaction of the service.

Messages may be commands that a service must handle.
Messages may be events that a service emits.
Messages may be documents that represent state or business data.

Handlers are the code that is executed over Messages.
Handlers may process Command Messages.
Handlers may process observed Events that 3rd party services emit.

Services SHOULD declare a manifest to map messages to handlers, which
allows Serf to route messages and to determine blocking or non-blocking modes.

Serf App and Channels
=====================

A Serf App is a Rack-like application that accepts an ENV hash as input.
This ENV hash is simply the hash representation of a message to be processed.
The Serf App, as configured by registered manifests, will:
1. route the ENV to the proper handler
2. run the handler in blocking or non-blocking mode.
  a. The handler's serf call method will parse the ENV into a message object
    if the handler registered a Message class.
3. publish the handler's results to results or error channels.
  a. These channels are normally message queuing channels.
  b. We only require the channel instance to respond to the 'publish'
    method and accept a message (or message hash) as the argument.
4. return the handler's results to the caller if it is blocking mode.
  a. In non-blocking mode, an MessageAcceptedEvent is returned instead
    because the message will be run by the EventMachine deferred threadpool
    by default.

Not implemented as yet:
1. Create a message queue listener or web endpoint to accept messages
  and run them through the built Serf App.
2. Message Queue channels to route responses to pub/sub locations.

Service Libraries
=================

1. Service Libraries SHOULD implement message classes that include the
  ::Serf::Message helper module.
  a. Barring that, they should conform to the idea that messages may be
    hashes that define at least one attribute: 'kind'.
2. Serialization of the messages SHOULD BE Json or MessagePack (I hate XML).
  a. `to_hash` is also included.
3. Handler methods MUST receive a message as either as an options hash
  (with symbolized keys) or an instance of a declared Message.
4. Handler methods MUST return zero or more messages.
5. Handler methods SHOULD handle catch their business logic exceptions and
  return them as specialized messages that can be forwarded down error channels.
  Uncaught exceptions that are then caught by Serf are published as
  generic Serf::CaughtExceptionEvents, and are harder to deal with.


Serf::Message
-------------

Users of the Serf::Message module need to be aware of that:

1. Messages MUST implement the `#attributes` method to use the
  default implementations of `to_msgpack`, `to_json`, and `to_hash`.
2. Messages MAY implement validation helpers (e.g. ActiveModel or
  Virtus + Aequitas (DataMapper)). This is purely to be helpful for
  receivers (Serf::Handlers) to validate the Messages before running
  code against its data. The Serf infrastructure code does not
  validate the Messages; it is the job of the handler code.
3. Messages MAY override `Message.parse` class method if they want
  different parsing (Message object instantiation) than
  `message_class.new *args`. This parse method is called in
  Serf::Handler when the handler class has defined a Message class
  to be used to deserialize the ENV for a handler action method.
3. Messages MAY override `Message#kind` instance method or `Message.kind`
  class method to specify a message `kind` that is different than
  the tableized name of the implementing ruby class.
4. Messages MAY override `Message#to_msgpack`, `Message#to_json`, or
  `Message#to_hash` to get alternate serialization.

User that opt to roll their own Message class only need to be
aware that:

1. Message classes MUST implement `Message.parse(env={})` class method
  if said message class is to be used as the target object representation
  of a received message (from ENV hash).
    a. Serf code makes this assumption when it finds an ENV
    hash that is to be parsed into a message object.


Example
=======

    # Require our libraries
    require 'active_model'
    require 'log4r'
    require 'json'

    require 'serf/builder'
    require 'serf/message'
    require 'serf/middleware/uuid_tagger'

    # create a simple logger for this example
    outputter = Log4r::FileOutputter.new(
      'fileOutputter',
      filename: 'log.txt')
    ['top_level',
      'serf',
      'handler',
      'results_channel',
      'error_channel'].each do |name|
      logger = Log4r::Logger.new name
      logger.outputters = outputter
    end

    # Helper class for this example to receive result or error messages
    # and pipe it into our logger.
    class MyChannel
      def initialize(logger)
        @logger = logger
      end
      def publish(message)
        @logger.info "#{message}"
      end
    end

    # my_lib/my_message.rb
    class MyMessage
      include Serf::Message
      include ActiveModel::Validations

      attr_accessor :data

      validates_presence_of :data

      def initialize(options={})
        @data = options[:data]
      end

      # We define this for Serf::Message serialization.
      def attributes
        { 'data' => data }
      end

    end

    # my_lib/my_handler.rb
    class MyHandler

      def initialize(options={})
        @logger = options[:logger]
      end

      def submit_my_message(message)
        @logger.info "In Submit My Message: #{message.to_json}"
        # Validate message because we have implement my_message with it.
        unless message.valid?
          raise ArgumentError, message.errors.full_messages.join(',')
        end
        # Do work Here...
        # And return 0 or more messages as result. Nil is valid response.
        return { kind: 'my_message_results' }
      end

      def submit_other_message(message={})
        # The message here is the ENV hash because we didn't declare
        # an :as option with `receives`.
        @logger.info "In Submit OtherMessage: #{message.inspect.to_s}"
        return [
          { kind: 'other_message_result1' },
          { kind: 'other_message_result2' }
        ]
      end

      def raises_error(message={})
        @logger.info 'In Raises Error, about to raise error'
        raise 'My Handler Runtime Error'
      end

      def regexp_matched(message={})
        @logger.info "RegExp Matched #{message.inspect}"
        nil
      end
    end

    # my_lib/routes.rb
    ROUTES = {
      # Declare a matcher and a list of routes to endpoints.
      'my_message' => [{
        # Declares which handler to use. This is the tableized
        # name of the class. It will be constantized by the serf code.
        handler: 'my_handler',
        action: :submit_my_message,

        # Define a parser that will build up a message object.
        # Default: nil, no parsing done.
        # Or name of registered parser to use.
        message_parser: 'my_parser',

        # Default is process in foreground.
        #background: false
      }],
      'other_message' => [{
        handler: 'my_handler',
        action: :submit_other_message,
        background: true
      }, {
        handler: 'my_handler',
        action: :raises_error,
        background: true
      }],
      /^events\/.*$/ => [{
        handler: 'my_handler',
        action: :regexp_matched,
        background: true
      }]
    }

    # Create a new builder for this serf app.
    builder = Serf::Builder.new do
      # Include some middleware
      use Serf::Middleware::UuidTagger

      # Registers routes from different service libary manifests.
      routes ROUTES

      # Can define arguments to pass to the 'my_handler' initialize method.
      handler 'my_handler', MyHandler.new(logger: ::Log4r::Logger['handler'])
      message_parser 'my_parser', MyMessage

      # Create result and error channels for the handler result messages.
      error_channel MyChannel.new(::Log4r::Logger['error_channel'])
      results_channel MyChannel.new(::Log4r::Logger['results_channel'])

      # We pass in a logger to our Serf code: Serfer and Runners.
      logger ::Log4r::Logger['serf']

      # Optionally define a not found handler...
      # Defaults to raising an ArgumentError, 'Not Found'.
      #not_found lambda {|x| puts x}
    end
    app = builder.to_app

    # Start event machine loop.
    logger = ::Log4r::Logger['top_level']
    EM.run do
      # On the next tick
      EM.next_tick do
        logger.info "Start Tick #{Thread.current.object_id}"

        # This will submit a 'my_message' message (as a hash) to the Serf App.
        # NOTE: We should get an error message pushed to the error channel
        #  because no 'data' field was put in my_message as required
        #  And the Result should have a CaughtExceptionEvent.
        results = app.call('kind' => 'my_message')
        logger.info "In Tick, MyMessage Results: #{results.inspect}"

        # Here is good result
        results = app.call('kind' => 'my_message', 'data' => '1234')
        logger.info "In Tick, MyMessage Results: #{results.inspect}"

        # This will submit 'other_message' to be handled in foreground
        # Because we declared the 'other_message' kind to be handled async, we
        # should get a MessageAcceptedEvent as the results.
        results = app.call('kind' => 'other_message')
        logger.info "In Tick, OtherMessage Results: #{results.inspect}"

        # This will match a regexp
        results = app.call('kind' => 'events/my_event')
        logger.info "In Tick, Regexp Results: #{results.inspect}"

        begin
          # Here, we're going to submit a message that we don't handle.
          # By default, an exception will be raised.
          app.call('kind' => 'unhandled_message_kind')
        rescue => e
          logger.warn "Caught in Tick: #{e.inspect}"
        end
        logger.info "End Tick #{Thread.current.object_id}"
      end
      EM.add_timer 2 do
        EM.stop
      end
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

