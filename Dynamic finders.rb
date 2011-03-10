module M 
  def self.included(cls)
    cls.class_eval do
        @@db = Hash.new
        @@index = 0
       def save()    
          if validate()
            key1 = self.instance_variables  
            key1.each do |key|
              key = /\w+/.match(key)
              @@db[key.to_s] ||= {}
            end #key1.each
            @@db.each_key { |key| @@db[key][@@index.to_s] = self.send key }
            @@index = @@index + 1
          end #if
       end #save
       def validate
        var = self.instance_variables 
        test = true
        var.each do |var1|
          var1 = /\w+/.match(var1)
          if (self.send var1.to_s ).length > 20
            puts "length of #{var1} should be less than 20 characters"
            test = false
          end #if
        end #var.each
        return test
      end #validate
      def self.method_missing(m, args)
        key = nil
        if m.to_s.start_with?("find_by_")
          temp = /(?<=find_by_).+/.match(m)
          temp = temp.to_s
          if @@db.has_key?(temp) 
            define_singleton_method("#{m}") do |args|
              if @@db[temp].has_value?(args)
                @@db[temp].each do |indx,value|             
                  key = indx    if(value == args)
                end  
              end  #if
              @@db.each_key{ |indx| print "#{indx}=>#{@@db[indx][key]}  " }
              print "\n"
            end #define_method
            #puts self.instance_methods.sort
            self.send "#{m}", args
          else
            puts "#{args} not found"  
          end
        else
          super
        end #if
      end #method_missing
    end
  end
end #module
class Play
  attr_accessor :fname,:lname
  def self.print_db
    puts @@db
  end
include M
end
class Game
   attr_accessor :fname,:lname
  def self.print_db
    puts @@db
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
p3 = Game.new
p3.fname = "vilok"
p3.lname = "aggarwal"
p3.validate
p3.save
Play.find_by_fname("gaurav")
#Play.find_by_fname("gaurav")

puts Play.print_db
#puts Play.instance_methods().sort
puts Game.print_db

