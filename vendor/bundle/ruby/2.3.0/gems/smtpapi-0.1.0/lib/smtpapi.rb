# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'smtpapi/version'
require 'json'

module Smtpapi
  #
  # SendGrid smtpapi header implementation
  #
  class Header
    attr_reader :to, :sub, :section, :category, :unique_args, :filters
    attr_reader :send_at, :send_each_at, :asm_group_id, :ip_pool

    def initialize
      @to = []
      @sub = {}
      @section = {}
      @category = []
      @unique_args = {}
      @filters = {}
      @send_at = nil
      @send_each_at = []
      @asm_group_id = nil
      @ip_pool = nil
    end

    def add_to(address, name = nil)
      if address.is_a?(Array)
        @to.concat(address)
      else
        value = address
        value = "#{name} <#{address}>" unless name.nil?
        @to.push(value)
      end
      self
    end

    def set_tos(addresses)
      @to = addresses
      self
    end

    def add_substitution(sub, values)
      @sub[sub] = values
      self
    end

    def set_substitutions(key_value_pairs)
      @sub = key_value_pairs
      self
    end

    def add_section(key, value)
      @section[key] = value
      self
    end

    def set_sections(key_value_pairs)
      @section = key_value_pairs
      self
    end

    def add_unique_arg(key, value)
      @unique_args[key] = value
      self
    end

    def set_unique_args(key_value_pairs)
      @unique_args = key_value_pairs
      self
    end

    def add_category(category)
      @category.push(category)
      self
    end

    def set_categories(categories)
      @category = categories
      self
    end

    def add_filter(filter_name, parameter_name, parameter_value)
      @filters[filter_name] = {} if @filters[filter_name].nil?
      if @filters[filter_name]['settings'].nil?
        @filters[filter_name]['settings'] = {}
      end
      @filters[filter_name]['settings'][parameter_name] = parameter_value
      self
    end

    def set_filters(filters)
      @filters = filters
      self
    end

    def set_send_at(send_at)
      @send_at = send_at
      self
    end

    def set_send_each_at(send_each_at)
      @send_each_at = send_each_at
      self
    end

    def set_asm_group(group_id)
      @asm_group_id = group_id
      self
    end

    def set_ip_pool(pool_name)
      @ip_pool = pool_name
      self
    end

    def to_array
      data = {}
      data['to'] = @to if @to.length > 0
      data['sub'] = @sub if @sub.length > 0
      data['section'] = @section if @section.length > 0
      data['unique_args'] = @unique_args if @unique_args.length > 0
      data['category'] = @category if @category.length > 0
      data['filters'] = @filters if @filters.length > 0
      data['send_at'] = @send_at.to_i unless @send_at.nil?
      data['asm_group_id'] = @asm_group_id.to_i unless @asm_group_id.nil?
      data['ip_pool'] = @ip_pool unless @ip_pool.nil?
      str_each_at = []
      @send_each_at.each do |val|
        str_each_at.push(val.to_i)
      end
      data['send_each_at'] = str_each_at if str_each_at.length > 0
      data
    end

    protected :to_array

    def json_string
      escape_unicode(to_array.to_json)
    end
    alias_method :to_json, :json_string

    def escape_unicode(str)
      str.unpack('U*').map do |i|
        if i > 65_535
          "\\u#{format('%04x', ((i - 0x10000) / 0x400 + 0xD800))}"\
          "\\u#{format('%04x', ((i - 0x10000) % 0x400 + 0xDC00))}" if i > 65_535
        elsif i > 127
          "\\u#{format('%04x', i)}"
        else
          i.chr('UTF-8')
        end
      end.join
    end
  end
end
