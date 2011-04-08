module Dynamic

# ahook method called whenever the module is included in class , here cls is the name of the class  

  def self.included(cls)
    cls.extend ClassMethods
    cls.send :class_variable_set, "@@db", []
    cls.send :class_variable_set, "@@validat", {}
    cls.send :class_variable_set, "@@attributes",[]
  end

# Execute the validator methods like validate_presence_of, called before the save method

  def execute_validators
    self.send :instance_variable_set, "@err", [] 
    validators = self.class.send :class_variable_get, "@@validat"   #if no validator are defined then return
      return  if validators.length == 0
    validators.each do |validator_name,validator_state| 
      validator_state.each do |validator_fields|
        if validator_fields.last.is_a?(Hash) 
          if validator_fields.last.has_key?(:if)
            validator_condition = validator_fields.last[:if]
            result = validator_condition.call(self)
            if !(result)     #if results in false then no need of validation fetch the next field and continue
              next
            end
          end   #validator_fields.last.has_key?(:if)
        end

        self.send validator_name, validator_fields  # call the specified validator function with call_type 
      end   #validator_state.each
    end     #validators.each

  end

# Saves the object by pushing it to an array, calls execute_validators,check_validation_errors

  def save()      

    execute_validators() 

    if self.class.instance_methods.include?(:validate) #check if valdators are present
      if validate()
        check_validation_errors
      else
        puts self.send :instance_variable_get, "@err"
        return false   
      end  #validate() return false
    
    else
        check_validation_errors
    end

  end

#check for validation errors if any in @err attribute

  def check_validation_errors

    if self.instance_variables.include?(:@err)
      if (self.send :instance_variable_get, "@err").length == 0     
        (self.class.send :class_variable_get, "@@db") << self
        return true
      else
        puts self.send :instance_variable_get, "@err"
        return false
      end
    else   #if @err is not yet initalized
      self.class.send :class_variable_get, "@@db" << self
      return true
    end     #instance_variable.include?(:@err)

  end

#checks that the values should be present for all the arguments of "*args"

  def presence(args)

    if args.last.is_a?(Hash)
      len = args.length - 2   
    else  
      len = args.length - 2
    end  

    err = self.send :instance_variable_get, "@err"
    args[0..len].each do |attr_name|  #here state represent the array of attributes for each statement of validates_presence_of written in class
      attr_name = attr_name.to_s  
      attr_value = self.send attr_name   
      if attr_value == nil
        if !(err.include?("#{attr_name.to_s} cannot be left blank or nil"))
          err << "#{attr_name.to_s} cannot be left blank or nil"
        end
      end
    end #args[0..len].each do |attr_name|
      
  end

#checks that the values should be of fixed length specified in :length attribute of args for all the arguments of "*args"

  def length(args)

    err = self.send :instance_variable_get, "@err"
    size = args.last[:length].to_i
    len = args.count-2
    args[0..len].each do |attr_name|          

      attr_name = attr_name.to_s
      attr_value = self.send attr_name
      if attr_value.to_s.length != size
        if !(err.include?("#{attr_name} should contain exactly #{size} characters"))
          err << "#{attr_name} should contain exactly #{size} characters"
        end
      end

    end #args[0..len].each do |attr_name|
    
  end

#checks that the values should satisfy the given regular expression for all the arguments of "*args"

  def format(args)

    err = self.send :instance_variable_get, "@err"
    reg_exp = args.last[:with] 
    len = args.count-2
    args[0..len].each do |attr_name| 

      attr_name = attr_name.to_s
        attr_value = self.send attr_name        
        if !reg_exp.match(attr_value)
          if !(err.include?("#{attr_name} is invalid"))
            err << "#{attr_name} is invalid"
          end
        end  

      end    #args[0..len].each do |attr_name| 
 
  end
# class_methods for class
  module ClassMethods

    include Enumerable

#To make it behave like enumerable

    def each

      (self.send :class_variable_get, "@@db").each {|obj| yield obj }

    end

# It finds the data for the field , example find_by_name("gaurav") , then temp = name and args = "gaurav"

    def my_each(attribute_name, attribute_value)

      @match_objects = []
	    each do |obj|
        @match_objects << obj      if((obj.send attribute_name) == attribute_value)
	    end
      @match_objects

    end

#Check if the given value is present as a key in database ,needed to check if dynamic finder is an attribute of the class

    def find_key(key)

      flag = false
      each do |obj|
        flag = true         if obj.respond_to?(key)
        break               if flag
      end
      flag

    end

# defined the missing function if it starts with find_by

    def method_missing(method_name, *argm)   

      if method_name.to_s.start_with?("find_by_")
        attr_name = method_name.to_s.split("find_by_").last.to_s       #get the name of the attribute
        attributes = send :class_variable_get, "@@attributes"
        if attributes.length == 0       #either the attributes are not defined or module has been             extended  after the creation of attributes
          if find_key(attr_name)
            create_method(method_name,attr_name)
          else
            super
          end

        else    #if attributes.length == 0

          if attributes.include?(attr_name.to_sym)
            create_method(method_name,attr_name)
          else
            super
          end

        end     #if attributes.length == 0       
        self.send "#{method_name}", *argm     #call the defined method
      else
        super
      end #if

    end #method_missing

# create new method with "name parameter" as name of method and "attr_name" isname of the attribute whose value is needed to be checked,calls my_each

    def create_method(name,attr_name)

      define_singleton_method("#{name}") do |*args|    #define the missing method
        array_objects = self.my_each(attr_name,*args)            
        if(array_objects.length > 0)
          p array_objects    
        else 
          puts "Element not found"
        end #if(arr.length > 0)
      end #define_method

    end

# This method simply adds the argument to @@validat     
#Syntax :- validate_presence_of attr_name1,attr_name2 :if => block ,here we can have any no. of attr_name separated by , and conditional :if block is as well optional.

    def validate_presence_of(*args)

        execute_validator("presence",*args)

    end

# This method simply adds the argument to @@validat    
#Syntax :- validate_length_of attr_name1,attr_name2, :length => value :if => block ,here we can have any no. of attr_name separated by , and conditional :if block is as well optional.

    def validate_length_of(*args)

        execute_validator("length",*args)

    end 

# This method simply adds the argument to @@validat     
#Syntax :- validate_length_of attr_name1,attr_name2, :with => regular_expression :if => block ,here we can have any no. of attr_name separated by , and conditional :if block is as well optional.

    def validate_format_of(*args)

        execute_validator("format",*args)

    end

#This function adds the validators to the @@validat class array

    def execute_validator(validator_name,*validator_values)

      validators = send :class_variable_get, "@@validat" 
      if validators.has_key?(validator_name)
        validators[validator_name] << validator_values      
      else
        validators[validator_name] = []
        validators[validator_name] << validator_values
      end 

    end

# creates a new object , assign it passed values and pass it to save function

    def create(args)

      if !(args.is_a?(Array))   #need to create multiple objects
        args = [args]
      end

      array_objects = []
      args.each do |elem|   #elem is an hash containing attributes needed for creating object
        obj =  self.new()     #new object
        elem.each do |attr_name, attr_val|  
          attr_name = attr_name.to_s + "="  #convert the key in the form of writer method like fname = 
          obj.send attr_name, attr_val    #call the function , e.g. fname=
        end

        yield(obj) if block_given?    #pass the object to block if given

        if obj.save                        #call the save function to save the object
          array_objects << obj
        end

      end   # args.each do |elem|
      if array_objects.length == 1    #check if single object was created or multiple
        array_objects.first
      else
        array_objects
      end

    end

# overriding attribute accessor function to know the list of attr_accessor

    def attr_accessor(*args)
      send :class_variable_set, "@@attributes", args
      super
    end

  end #ClassMethods
end #class

class Play

  include Dynamic
  attr_accessor :fname,:lname,:age

#  validate_presence_of "lname", :if => Proc.new{|user| user.fname.nil?}
#  validate_presence_of "fname", :if => Proc.new{|user| user.age.nil?}
#  validate_format_of :age, :with => /^\d{2}$/, :if => Proc.new{|user| user.fname.nil?} 
#   validate_length_of :age, :length => 2, :if => Proc.new{|user| user.age.nil?}
#  validate_length_of "fname", "5" # :if => Proc.new{|user| user.fname.nil?}    

  def self.print_db
    p @@db
  end

  def self.clear_db
    @@db = []
  end

  def validate
   true
  end

end
p2 = Play.new
p2.fname = "midha"
p2.lname = "23"
p2.age = "2123ab"
p2.save

p1 = Play.new
p1.fname = "gaurav"
p1.lname = "midha"
p1.age = "231"
p1.save

Play.find_by_fname("gaurav")

#s = Play.create(:fname=>"gaurav", :lname=>"midha")
#s = Play.create([{ :fname => 'Jamie', :lname => "midha" }, { :fname => 'Jeremy' }])

#s = Play.create(:fname=>"gaurav1", :lname=>"midha1")do |u|
#      u.age = "11"
#    end

#s = Play.create([{ :fname => 'Jamie1' }, { :fname => 'Jeremy2', :age => 2, :lname => "test" }])do |u|
#      u.lname = u.fname
#    end
