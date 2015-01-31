module Bookbinder

  UserMessage = Struct.new(:message, :escalation_type)
  EscalationType = OpenStruct.new(success: 0, error: 1, warn: 2)

end
