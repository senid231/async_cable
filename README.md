# AsyncCable

Dead simple websocket middleware for Rack async app.

Intended to use with [Falcon web server](https://github.com/socketry/falcon) or other web server based on [Async](https://github.com/socketry/async).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'async_cable'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install async_cable

## Usage

`config.ru`
```ruby
class MainCable < AsyncCable::Connection
  identified_as :main

  def on_open
    @identifier = request.session['user_id']
    logger.debug { "#{self.class}#on_open identifier=#{identifier}" }

    if @identifier.nil?
      logger.debug { "#{self.class}#on_open unauthorized" }
      send_close 1401, 'unauthorized'
      return
    end

    payload = { message: "#{identifier} has joined", who: '<Server>' }
    self.class.broadcast_to(payload)
  end

  def on_data(data)
    logger.debug { "#{self.class}#on_data identifier=#{identifier} data=#{data}" }
    transmit(message: "message received", who: '<Server>')
    payload = { message: data[:message], who: identifier }
    self.class.broadcast_to(payload, except: [identifier])
  end

  def on_close
    return if identifier.nil?

    logger.debug { "#{self.class}#on_close identifier=#{identifier}" }
    payload = { message: "#{identifier} has left", who: '<Server>' }
    self.class.broadcast(payload)
  end
end
```

example of JS code for connecting with websocket server 
```js
  var socket = new WebSocket("ws://localhost:4567/cable");
  socket.onopen = function(_event) { 
    console.log("WebSocket connected"); 
  };
  socket.onerror = function(error) { 
    console.log("WebSocket error", error); 
  };
  socket.onclose = function(event) { 
    console.log("WebSocket closed", event.wasClean, event.code, event.reason);
  };
  socket.onmessage = function(event) { 
    console.log("WebSocket data received", JSON.parse(event.data)); 
  };

  var transmit = function (data) {
    socket.send( JSON.generate(data) );
  };
  var close = function (code, reason) {
    socket.close(code || 1000, reason);
  };
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/senid231/async_cable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/async_cable/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AsyncCable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/async_cable/blob/master/CODE_OF_CONDUCT.md).
