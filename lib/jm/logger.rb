# Default logger, which really just PUTS everything.  


module JM
  class Logger
    def info str
      puts str
    end
    
    def error str
      puts "ERROR: #{str}"
    end
    
    def warn str
      puts "WARNING: #{str}"
    end
    
  end
  
  
end