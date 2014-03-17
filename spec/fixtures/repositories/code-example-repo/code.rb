puts 'first_example'
numbers = 12.times.map do
  rand(64)
end

numbers.reduce(:+) / numbers.length

puts 'second_example'

# code_snippet complicated_function start ruby
fib = Enumerator.new do |yielder|
  i = 0
  j = 1
  loop do
    i, j = j, i + j
    yielder.yield i
  end
end

p fib.take_while { |n| n <= 4E6 }
# => [1, 1, 2 ... 1346269, 2178309, 3524578]
# code_snippet complicated_function end

this.is.code('whee')

{:some => 'more'}

'
# code_snippet simple_configuration start yaml

repo:
- this_is_yaml
- whyyyyyyyyy

# code_snippet simple_configuration end
'


# code_snippet typeless_stuff start

this = untyped_code

# code_snippet typeless_stuff end




# code_snippet bad_start_tag

this.has bad_start_tag

# code_snippet bad_start_tag end




# code_snippet bad_end_tag start

this.has bad_end_tag

# code_snippet bad_end_tag
