require 'ostruct'

module Bookbinder
  UserMessage = Struct.new(:message, :escalation_type) do
    def error?
      escalation_type == EscalationType.error
    end

    def warn?
      escalation_type == EscalationType.warn
    end
  end

  EscalationType = OpenStruct.new(success: 0, error: 1, warn: 2)
end
