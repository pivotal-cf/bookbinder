# -*- encoding: utf-8 -*-
require 'test/unit'
require './lib/smtpapi'

#
# SmtpapiTest implementation
#
class SmtpapiTest < Test::Unit::TestCase
  def test_version
    assert_equal('0.1.0', Smtpapi::VERSION)
  end

  def test_empty
    header = Smtpapi::Header.new
    assert_equal('{}', header.json_string)
  end

  def test_add_to
    header = Smtpapi::Header.new
    header.add_to('you@youremail.com')
    header.add_to('other@otheremail.com', 'Other Name')
    assert_equal(
      '{"to":["you@youremail.com","Other Name <other@otheremail.com>"]}',
      header.json_string)
  end

  def test_add_to_array
    header = Smtpapi::Header.new
    header.add_to(['you@youremail.com', 'my@myemail.com'])
    assert_equal(
      '{"to":["you@youremail.com","my@myemail.com"]}',
      header.json_string)
  end

  def test_set_tos
    header = Smtpapi::Header.new
    header.set_tos(['you@youremail.com', 'other@otheremail.com'])
    assert_equal(
      '{"to":["you@youremail.com","other@otheremail.com"]}',
      header.json_string)
  end

  def test_add_substitution
    header = Smtpapi::Header.new
    header.add_substitution('keep', ['secret'])
    header.add_substitution('other', %w(one two))
    assert_equal(
      '{"sub":{"keep":["secret"],"other":["one","two"]}}',
      header.json_string)
  end

  def test_set_substitutions
    header = Smtpapi::Header.new
    header.set_substitutions('keep' => ['secret'])
    assert_equal('{"sub":{"keep":["secret"]}}', header.json_string)
  end

  def test_add_section
    header = Smtpapi::Header.new
    header.add_section('-charge-', 'This ship is useless.')
    header.add_section('-bomber-', 'Only for sad vikings.')
    assert_equal(
      '{"section":'\
        '{"-charge-":"This ship is useless.",'\
          '"-bomber-":"Only for sad vikings."}}',
      header.json_string)
  end

  def test_set_sections
    header = Smtpapi::Header.new
    header.set_sections('-charge-' => 'This ship is useless.')
    assert_equal(
      '{"section":{"-charge-":"This ship is useless."}}',
      header.json_string
    )
  end

  def test_add_unique_arg
    header = Smtpapi::Header.new
    header.add_unique_arg('cat', 'dogs')
    assert_equal('{"unique_args":{"cat":"dogs"}}', header.json_string)
  end

  def test_set_unique_args
    header = Smtpapi::Header.new
    header.set_unique_args('cow' => 'chicken')
    header.set_unique_args('dad' => 'proud')
    assert_equal('{"unique_args":{"dad":"proud"}}', header.json_string)
  end

  def test_add_category
    header = Smtpapi::Header.new
    header.add_category('tactics')
    header.add_category('advanced')
    assert_equal('{"category":["tactics","advanced"]}', header.json_string)
  end

  def test_set_categories
    header = Smtpapi::Header.new
    header.set_categories(%w(tactics advanced))
    assert_equal('{"category":["tactics","advanced"]}', header.json_string)
  end

  def test_add_filter
    header = Smtpapi::Header.new
    header.add_filter('footer', 'enable', 1)
    header.add_filter('footer', 'text/html', '<strong>boo</strong>')
    assert_equal(
      '{"filters":'\
        '{"footer":'\
          '{"settings":'\
            '{"enable":1,'\
              '"text/html":"<strong>boo</strong>"'\
            '}'\
          '}'\
        '}'\
      '}',
      header.json_string
    )
  end

  def test_set_filters
    header = Smtpapi::Header.new
    filter = {
      'footer' => {
        'setting' => {
          'enable' => 1,
          'text/plain' => 'You can haz footers!'
        }
      }
    }
    header.set_filters(filter)
    assert_equal(
      '{"filters":'\
        '{"footer":'\
          '{"setting":'\
            '{"enable":1,"text/plain":"You can haz footers!"}'\
          '}'\
        '}'\
      '}',
      header.json_string
    )
  end

  def test_add_category_unicode
    header = Smtpapi::Header.new
    header.add_category('Martí')
    header.add_category('天破活殺')
    header.add_category('天翔十字鳳')
    assert_equal(
      '{"category":'\
        '["Mart\\u00ed",'\
          '"\\u5929\\u7834\\u6d3b\\u6bba",'\
          '"\\u5929\\u7fd4\\u5341\\u5b57\\u9cf3"]}',
      header.json_string
    )
    header.add_category('鼖')
    assert_equal(
      '{"category":'\
        '["Mart\\u00ed",'\
          '"\\u5929\\u7834\\u6d3b\\u6bba",'\
          '"\\u5929\\u7fd4\\u5341\\u5b57\\u9cf3",'\
          '"\\ud87e\\ude1b"]}',
      header.json_string
    )
  end

  def test_sent_send_at
    header = Smtpapi::Header.new
    localtime = Time.local(2014, 8, 29, 17, 56, 35)
    header.set_send_at(localtime)

    assert_equal("{\"send_at\":#{localtime.to_i}}", header.json_string)
  end

  def test_send_each_at
    header = Smtpapi::Header.new
    localtime1 = Time.local(2014,  8, 29, 17, 56, 35)
    localtime2 = Time.local(2013, 12, 31,  0,  0,  0)
    localtime3 = Time.local(2015,  9,  1,  4,  5,  6)
    header.set_send_each_at([localtime1, localtime2, localtime3])

    assert_equal(
      '{"send_each_at":'\
        "[#{localtime1.to_i},#{localtime2.to_i},#{localtime3.to_i}]"\
      '}',
      header.json_string
    )
  end

  def test_asm_group_id
    header = Smtpapi::Header.new
    header.set_asm_group(2)

    assert_equal('{"asm_group_id":2}', header.json_string)
  end

  def test_ip_pool
    header = Smtpapi::Header.new
    header.set_ip_pool('test_pool')

    assert_equal('{"ip_pool":"test_pool"}', header.json_string)
  end
end
