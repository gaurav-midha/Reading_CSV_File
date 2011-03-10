module M 
#  @@db = []
#  @@index = 0

  def self.included(cls)
    cls.extend ClassMethods
    cls.send :class_variable_set, "@@db", []
  end
  def save()    
    if validate()    
      @@db = self.class.send :class_variable_get, "@@db"
      @@db << self
    end
  end
  def validate
    var = self.instance_variables 
    test = true
    var.each do |var1|
      var1 = /\w+/.match(var1)
      if (self.send var1.to_s ).length > 20
        puts "length of #{var1} should be less than 20 characters"
        test = false
      end
    end
    return test
  end

  module ClassMethods
      def my_each(temp, *args)
        a = self.send :class_variable_get, "@@db"
        @arr = []
        temp1 = /(?<=\:\@).+/.match(temp)
	      for i in 0...(a.length) 
          res = a[i].send temp1.to_s
          if (res == args[0])
            @arr << a[i]
          end
	      end
        return(@arr)
      end
      def method_missing(m, *args)
        @@db = self.send :class_variable_get, "@@db"
        #@@index = self.send :class_variable_get, "@@index"
        if m.to_s.start_with?("find_by_")
          temp = /(?<=find_by_).+/.match(m)
          temp = ":@" + temp.to_s
          define_singleton_method("#{m}") do |*args|
            arr = self.my_each(temp,*args)            
            if(arr.length > 0)
              p arr    
            else 
              puts "Element not found"
            end     
          end #define_method
          self.send "#{m}", *args
        else
          super
        end #if
      end #method_missing
  end #ClassMethods
end #class
class Play
  attr_accessor :fname,:lname
  def self.print_db
    p @@db
  end
include M
end
p1 = Play.new
p1.fname = "gaurav"
p1.save
#puts Play.print_db
p2 = Play.new
p2.fname = "khushi"
p2.lname = "yadav"
p2.save
#puts Play.print_db
p3 = Play.new
p3.fname = "vilok"
p3.lname = "aggarwalsjj"
p3.validate
p3.save
#Play.print_db
#Play.find_by_fname("gaurav")
Play.find_by_fname("khushi")
Play.find_by_fname("gaurav")

