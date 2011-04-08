require 'csv'

puts "enter the path of the csv file"
file_addr = gets.chomp

#getting the name of the class
class_name = file_addr.split("/").last.split(".").first.capitalize
file_data = CSV.read(file_addr)

method_names = file_data.delete_at(0)
#creating the class
klass = Object.const_set(class_name,Class.new) 

#class_eval will make the functions instance method(available to the objects)
klass.class_eval do
   method_names.each {|method|	attr_accessor method }
end

s = []
i = 0
file_data.each do |data_row|
	  s[i] = klass.new									

    method_names.each_with_index do |method,index|
	    	s[i].send "#{method}=", data_row[index]			
	    	puts "s[#{i}].#{method} = #{s[i].send(method)}"		
	  end

    i = i + 1
end
