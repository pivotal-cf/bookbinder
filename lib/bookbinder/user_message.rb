module Bookbinder

  UserMessage = Struct.new(:message, :escalation_type)
  EscalationType = OpenStruct.new(error: 0, success: 1)

end
