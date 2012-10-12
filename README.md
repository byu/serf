serf
====

Build your System with Commands, Event Sourcing and Message Passing.


Commands
--------

The Unit of Work to be done. This takes in a request, represented
by a "Message", and returns an "Event" as its result. The command class
is the "Interactor" or "Domain Controller" with respect to performing
Domain Layer business logic in coordinating and interacting with
the Domain Layer's Entities (Value Objects and Entity Gateways).

1. Include the "Serf::Command" module in your class.
2. Implement the 'call(headers, message)' method.
3. Return nil or a Message (Hashie::Mash is recommended).

Notes:

* Exceptions raised out of the command are then caught by Serf and
  transformed into a generic CaughtExceptionEvent Message.
* Multiple Commands may be triggered to execute from a single request Message.

Parcels
-------

A Parcel is just the package of Headers and Message. Serf's convention
represents requests and responses as (mostly) just Plain Old Hash Objects
(POHO as opposed to PORO) over the Boundaries (see Architecture Lost Years).
This simplifies marshalling over the network. It also gives us easier
semantics in defining Request and Responses without need of extra classes,
code, etc.

The Parcel in Ruby (Datastructure) is represented in three forms:

1. Serf::Parcel object, subclass of Hashie::Dash.
  a. An object that has hash-like access to headers and message,
    accessible both as 'headers' or :headers.
  b. An object w/ property accessors. `parcel.headers = {}`
  c. A splat-able object.
    Serf::Parcel.new {}, {}
    headers, message = parcel_object
2. Parcel Pair - [headers, message], a 2 element tuple (Array).
3. Parcel Hash - { headers: headers, message: message}, a 2 element Hash.

NOTE: Hashie::Mash is *Awesome*. (https://github.com/intridea/hashie)
NOTE: Serf passes headers and message as frozen Hashie::Mash instances
  to Commands' call method.
NOTE: Serf mainly deals with Serf::Parcels, returning instances as responses.

*Messages* are the representation of a Business Request or Business Event.

In the parcel, the message is the business data. It specifies what
business work needs to be done, or what business was done.

  REQUIRED: Required by all messages is the 'kind' field.

The "kind" field identifies the ontological meaning of the message, which
allows Serf to properly pass the message onto the proper Command.
The convention is 'mymodule/requests/my_business_equest' for Requests,
and 'mymodule/events/my_business_event' for Events.

  RECOMMENDED: Use JSON Schema to validate the structure of a message.
    https://github.com/hoxworth/json-schema
    This can be implemented in the 'Policy' chain.

*Headers* are the processing meta data that is associated with a Message.

Headers provide information that would assist in processing, tracking
a Message. But does not provide business relevant information to
the Request or Event Message.

Examples are:
* UUIDs to track request and events, providing a sequential order of
  execution of commands. (Already Implemented by Serf).
* Current User that sent the request. For authentication and authorization.
* Host and Application Server that is processing this request.

Generally, the header information is populated only by the infrastructure
that hosts the business commands. The commands themselves do not
return any headers in the response. The commands are tasked to provide
only business relevant data in the Event messages they return.

Also note that Headers are passed to the commands. This allows commands
to possibly do extra processing based on who made the request.

Policies
--------

Serf implements Policy Chains to validate, check the incoming Parcel before
actually executing a Command.

Example Benefits:
* Authorization to execute Command.
* Validation of Message schema

Policies only need to implement a single method:

    def check!(headers, message)
      raise 'Failure' # To fail the policy, raise an error.
    end
  
Channels
--------

A simple Serf App is a Rack-like app that takes Requests, executes Commands
and returns Events. Channels provide the abstraction for Message Passing
that will feed Events back into Event Handlers (More Serf App Commands),
which can spin off additional business Requests (back into other Serf Apps).
(See CQRS).

Channels just need to implement the following method:

    def push(parcel)
    end

The parcel is a "Parcel Pair". The channel is responsible for serializing
the parcel into a wire-format to transfer over the network to receiving
Serf Apps.


References
==========

Keynote: Architecture the Lost Years, by Robert Martin
  * http://confreaks.com/videos/759

Domain Driven Design by Eric Evans:
  * http://books.google.com/books?id=7dlaMs0SECsC&dq=domain+driven+design

Patterns of Enterprise Application Architecture by Martin Fowler
  * http://martinfowler.com/books/eip.html
  * Command (Unit of Work) Pattern
  * Event Sourcing

Enterprise Integration Patterns by Hohpe and Woolf
  * http://www.eaipatterns.com/

DDD for Rails Developers Series:
  * http://rubysource.com/ddd-for-rails-developers-part-1-layered-architecture/
  * http://rubysource.com/ddd-for-rails-developers-part-2-entities-and-values/ 
  * http://rubysource.com/ddd-for-rails-developers-part-3-aggregates/

DCI in Ruby
  * Maybe use DCI to better manage business logic in Entities.
  * http://mikepackdev.com/blog_posts/24-the-right-way-to-code-dci-in-ruby
  * http://mikepackdev.com/blog_posts/35-dci-with-ruby-refinements
  * http://nicksda.apotomo.de/2011/12/ruby-on-rest-2-representers-and-the-dci-pattern/

CQRS
  * http://www.udidahan.com/2009/12/09/clarified-cqrs/
  * http://elegantcode.com/2009/11/11/cqrs-la-greg-young/
  * http://elegantcode.com/2009/11/20/cqrs-the-domain-events/

Life beyond Distributed Transactions: an Apostate’s Opinion by Pat Helland
  * http://www.ics.uci.edu/~cs223/papers/cidr07p15.pdf

Building on Quicksand by Pat Helland
  * http://arxiv.org/ftp/arxiv/papers/0909/0909.1788.pdf

The Domain Layer (from DDD):

1. Entities (Model Entities)- What your application is.
  * Also remember Value Objects.
  * How your Domain Model is structured, but NOT necessarily tied to the
    underlying storage infrastructure.
  * http://rubysource.com/ddd-for-rails-developers-part-2-entities-and-values/
2. Domain Controllers (Interactors) - What your application does.
  * The business logic of coordinating different entities.
    Different than a Rails controller.
  * Keynote: Architecture The Lost Years
    Robert Martin
    Ruby Midwest 2011
    http://confreaks.com/videos/759
  * Your Rails Application is Missing a Domain Controller
    Nicholas Henry
    http://blog.firsthand.ca/2011/12/your-rails-application-is-missing.html
3. There is a balancing game of what business logic code lives in an
    Entity vs a Domain Controller... Do what works for you.


Example
=======

    # Require our libraries
    require 'json'
    require 'yell'

    require 'serf/builder'
    require 'serf/command'
    require 'serf/middleware/parcel_tapper'
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

    ##
    # Make a simple example channel
    class MyChannel

      def initialize(name)
        @logger = Yell.new STDOUT, format: "CHANNEL(#{name}): %m"
      end

      def push(parcel)
        # nominally push this parcel into some messaging fabric
        @logger.info parcel.to_json
      end

    end

    # Create a new builder for this serf app.
    builder = Serf::Builder.new do
      use(
        Serf::Middleware::ParcelTapper,
        request_channel: MyChannel.new('request'),
        response_channel: MyChannel.new('response'),
        logger: MyChannel.new('response'))

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

    # Here, we're going to submit a message that we don't handle.
    my_logger.info 'Call 5: Start'
    results = app.call(nil, kind: 'unhandled_message_kind')
    my_logger.info "Call 5: #{results.size} #{results.to_json}"


Contributing
============

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Copyright
=========

Copyright (c) 2011-2012 Benjamin Yu. See LICENSE.txt for further details.

