# computed_attribute

ComputedAttribute adds cached attributes to ActiveRecord models and automatically updates them, allowing you to cut down on expensive database queries by storing computed attributes directly in the record. Attributes can auto-update based on a model's associations or other attributes.

## Status
This is alpha software and is being actively developed. That said, I’ve been using it on production in a large Rails app without a hitch. Bug reports and pull requests are welcome!

## Features
* Works with all ActiveRecord association types
* Manually recompute a value when not using associations
* No monkey patching

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'computed_attribute'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install computed_attribute

## Usage

All computed attributes are stored in a column on your model’s database table:

1. Add a database column to store the value (e.g. `completed_at`)
2. Include the module in your model and use the `computed_attribute` method to define the attribute
3. Add a `computed_{attribute_name}` method to your model that will be used to calculate the value

### Association attributes
For attributes that are calculated based on a model’s associations, use the `depends:` option to specify which associations this attribute depends on:

```ruby
class Order < ActiveRecord::Base
  include ComputedAttribute::Core

  has_many :logs

  computed_attribute :completed, depends: :logs

  def computed_completed
    logs.find_by { |log| log.key == :completed }.present?
  end
end
```

When one of this order's `logs` are created, saved, or deleted, `:completed` will automatically be re-calculated:

```ruby
order = Order.new
order.completed #=> false
order.logs.create(key: :completed)
order.completed #=> true
order.logs.destroy_all
order.completed #=> false
```

That’s all there is to it!

### Model attributes
For attributes that depend not on associations but on *other* attributes of the model, use the `save: true` option to have the attribute auto-update when the model itself is saved:

```ruby
class Circle < ActiveRecord::Base
  computed_attribute :circumference, save: true

  def computed_circumference
    return 0 if radius.nil?
    radius * 2 * Math::PI
  end
end
```

### Manual updates
If you have an attribute that depends on something external from your model, you can manually re-calculate it at any time using the `recompute` method:

```ruby
Order.recompute(:all) # recompute all computed attributes on all orders
Order.recompute(:completed) # recompute just the `completed` attribute on all orders
order.recompute(:all) # recompute all computed attributes on a single order
order.recompute(:completed) # recompute just the `completed` attribute on a single order
```

If your non-association attribute can tolerate some staleness, you might consider putting the recomputation in a recurring background worker.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joshleitzel/computed_attribute. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
