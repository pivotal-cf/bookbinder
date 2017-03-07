# smtpapi-ruby

This ruby gem allows you to quickly and more easily generate SendGrid X-SMTPAPI headers.

[![Build Status](https://travis-ci.org/sendgrid/smtpapi-ruby.svg?branch=master)](https://travis-ci.org/SendGrid/smtpapi-ruby)

## Installation

Add this line to your application's Gemfile:

    gem 'smtpapi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smtpapi

## Usage

### Initializing

```ruby
header = Smtpapi::Header.new
```

### to_json

This gives you back the stringified json formatted X-SMTPAPI header.

```ruby
header = Smtpapi::Header.new
header.to_json
```

### add_to

```ruby
header    = Smtpapi::Header.new
header.add_to('you@youremail.com')                            # to => ['you@youremail.com']
header.add_to('other@otheremail.com', 'other')                # to => ['you@youremail.com', 'other <other@otheremail.com>']
header.add_to(['you@youremail.com', 'other@otheremail.com'])  # to => ['you@youremail.com', 'other <other@otheremail.com>', 'you@youremail.com', 'other@otheremail.com']
```

### set_tos

```ruby
header    = Smtpapi::Header.new
header.set_tos(['you@youremail.com', 'other@otheremail.com']) # to => ['you@youremail.com', 'other@otheremail.com']
```

### add_substitution

```ruby
header    = Smtpapi::Header.new
header.add_substitution('keep', ['secret'])        # sub = {keep: ['secret']}
header.add_substitution('other', ['one', 'two'])   # sub = {keep: ['secret'], other: ['one', 'two']}
```

### set_substitutions

```ruby
header    = Smtpapi::Header.new
header.set_substitutions({'keep' => 'secret'})  # sub = {keep: ['secret']}
```

### add_unique_arg

```ruby
header    = Smtpapi::Header.new
header.add_unique_arg('cat', 'dogs')
```

### set_unique_args

```ruby
header    = Smtpapi::Header.new
header.set_unique_args({'cow' => 'chicken'})
header.set_unique_args({'dad' => 'proud'})
```

### add_category

```ruby
header    = Smtpapi::Header.new
header.add_category('tactics') # category = ['tactics']
header.add_category('advanced') # category = ['tactics', 'advanced']
```

### set_categories

```ruby
header    = Smtpapi::Header.new
header.set_categories(['tactics', 'advanced']) # category = ['tactics', 'advanced']
```

### add_section

```ruby
header    = Smtpapi::Header.new
header.add_section('-charge-', 'This ship is useless.')
header.add_section('-bomber-', 'Only for sad vikings.')
```

### set_sections

```ruby
header    = Smtpapi::Header.new
header.set_sections({'-charge-' => 'This ship is useless.'})
```

### add_filter

```ruby
header    = Smtpapi::Header.new
header.add_filter('footer', 'enable', 1)
header.add_filter('footer', 'text/html', '<strong>boo</strong>')
```

### set_filters

```ruby
header    = Smtpapi::Header.new
filter = {
  'footer' => {
    'setting' => {
      'enable' => 1,
      "text/plain" => 'You can haz footers!'
    }
  }
}
header.set_filters(filter)
```

### set_send_at

```ruby
header    = Smtpapi::Header.new
lt = Time.local(2014, 8, 29, 17, 56, 35)
header.set_send_at(lt)
```

### set_send_each_at

```ruby
header    = Smtpapi::Header.new
lt1       = Time.local(2014,  8, 29, 17, 56, 35)
lt2       = Time.local(2013, 12, 31,  0,  0,  0)
lt3       = Time.local(2015,  9,  1,  4,  5,  6)
header.set_send_each_at([lt1, lt2, lt3])
```

### asm_group_id

This is to specify an [ASM Group](https://sendgrid.com/docs/User_Guide/advanced_suppression_manager.html) for the message.

```ruby
header = Smtpapi::Header.new
header.set_asm_group(2)
```

### set_ip_pool

[Using IP Pools with the SMTP API Header](https://sendgrid.com/docs/API_Reference/Web_API_v3/IP_Management/ip_pools.html)
```ruby
header = Smtpapi::Header.new
header.set_ip_pool("test_pool")
```

## Contributing

1. Fork it ( http://github.com/sendgridjp/smtpapi-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Running Tests

The existing tests in the `test` directory can be run using test gem with the following command:

```bash
rake test
```

## Credits

This library was created by [Wataru Sato](https://github.com/awwa) and is now maintained by SendGrid.
