
def generic_action
   lambda {|x| puts "generic action called: #{x}";true} 
end

def generic_handler
   lambda {|x| puts "generic handler called: #{x}";true} 
end