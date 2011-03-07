#reading the file 
puts "enter the path of the csv file"
file_addr = gets.chomp
file1 = File.new("#{file_addr}")
file_data = file1.read()
#getting the name of the class
class_name = file_addr.split("/").reverse[0].split(".")[0]
class_name[0] = class_name[0].capitalize 
#splitting the file data linewise
file_data = file_data.split("\n")
#splitting the first row of data
met_name = file_data[0].split(",")
#creating the class
klass = Object.const_set(class_name,Class.new) 
#class_eval will make the functions instance method(available to the objects)
klass.class_eval do 
#Constructing methods for the first row of csv file
	for i in 0...(met_name.length)
		attr_accessor met_name[i]
	end
end
s = []
#calling methods and linking the data with the array of objects
for i in 1...(file_data.length)
	s[i - 1] = klass.new																#construct a new class object
	cur_data = file_data[i].split(",")							#split the curent row
	for j in 0...(met_name.length)
		s[i - 1].send "#{met_name[j]}=", cur_data[j]			#call the method to insert the data
		puts "s[#{i - 1}].#{met_name[j]} = #{s[i - 1].send(met_name[j])}"		
	end
end

