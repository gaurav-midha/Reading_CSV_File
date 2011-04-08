module Filter
  def self.included(cls)
    cls.extend ClassMethods
    cls.send :class_variable_set, "@@bef_except_elem", []
    cls.send :class_variable_set, "@@bef_only_elem", []
    cls.send :class_variable_set, "@@aft_except_elem", []
    cls.send :class_variable_set, "@@aft_only_elem", []
  end
  module ClassMethods
    
#gets the list of attributes to be called before or after a element determine by the call_type
#here src is the array from which method names should be determined and name is the name of the method and call_type defines that the function is called for :after or :before     

    def get_only_except_elem(src,name,call_type)
      result = []    
      array_filters = send :class_variable_get, "#{src}"
      array_filters.each do |state|
        if state.class == Hash
          state.each do |filter_meth,filter_on|
            if call_type == :except
              condtn = !(filter_on.include?(name.to_s))
            else
              condtn = (filter_on.class == Array) && (filter_on.include?(name.to_s))
            end 
            if condtn
              result << filter_meth.to_s               
            end
          end 
        end   #if hash.class == Hash
      end
      result     
    end

#gets the list of methods which should be called before or after the method {name} 
# "name" is the name of function and filt is type of call it is for :before or :after 

    def find_except(name,filt)
#use exact value for filter matching  
      if filt == :before
        src1 = "@@bef_except_elem"    
        src2 = "@@bef_only_elem"
      else
        src1 = "@@aft_except_elem"
        src2 = "@@aft_only_elem"
      end

        result = [] 
        (get_only_except_elem(src1,name,:except)).each{|key| result << key}
        (get_only_except_elem(src2,name,:only)).each{|key| result << key}
        result
    end

#whenever a new method is added alias it to a diffrent name and define amethod with the original name which first calls the method specified in before and then the original method and then after method  

    def method_added(name)

# if new method is an alias method of some method then no need to alias it again
      if /hook/.match(name.to_s) or method_defined?("#{name}_without_hook") or ["before_method","after_method"].include?(name.to_s)
       return
      end  

      call_bef = find_except(name,:before)   #finds function which should be called before/after this fuction
      call_aft = find_except(name,:after)
      if call_bef.length == 0 && call_aft.length == 0 
        return
      end  

      if call_bef.include?(name.to_s) or call_aft.include?(name.to_s) #To avoid infinite loop
        return
      end

# define new method
      hook  = %{
                def #{name}_hook
                 call_bef = self.class.find_except(\"#{name}\",:before)
                 call_bef.each{|elem| send elem}
                 #{name}_without_hook()
                 call_aft = self.class.find_except(\"#{name}\",:after)
                 call_aft.each{|elem| send elem}
                end
              }

      self.class_eval(hook)
      a1 = "alias #{name}_without_hook #{name}"
      self.class_eval(a1)
      a2 = "alias #{name} #{name}_hook"
      self.class_eval(a2)

    end

#initialize the bef_only_elem/bef_except_elem and aft_only_elem/aft_except_elem determine by the call_type
#call_type can be :only/:except, elem contains passed :only/:except array, cal_met will contain all the methods which should be caled bef/aft an method, prop will contain :only/:except

    def initialize_only_except(call_type,elem,cal_method,filt)
#state contain a list of element before which the "x" function should be called and "x" will become keyname
      state = {} 
      cal_method.each do |method|
        state[method] = elem
      end

      if call_type.to_sym == :before
        (send :class_variable_get, "@@bef_#{filt.to_s}_elem") << state
      else
        (send :class_variable_get, "@@aft_#{filt.to_s}_elem") << state
      end

    end

#initialize the bef_only_elem/aft_only_elem and bef_except_elem/aft_except_elem determine by the call_type

    def initialize_bef_aft(call_type,*args)

     cal_method = []   #Will contain list of methods to be called before 
     flag = 0
     args.each do |method|        
      if method.class == Hash
        if method.has_key?(:only)
          flag = 1
          initialize_only_except(call_type,method[:only],cal_method,"only")
        elsif method.has_key?(:except)
          flag = 1
          initialize_only_except(call_type,method[:except],cal_method,"except")       
        else
          abort("undefine attributes send to method #{call_type}")
        end
      
      else
        cal_method << method
      end
     end

     if flag == 0 # if :only and :except both are not given then it should be called before all functions 
       initialize_only_except(call_type,Array.new,cal_method,:except)
     end 

    end

# adds the list of all the methods passed to before method to 2 arrays @@bef_only_elem and @@bef_except_elem 

    def before_method(*args)
      initialize_bef_aft("before",*args)
    end

    def after_method(*args)
      initialize_bef_aft("after",*args)
    end

  end 
end

class Play
  include Filter
  before_method "a", "c", :except=>["c","b"] 
  after_method  "b", :except=>["fname"]

  def fname
    puts "fname"
  end

  def a
    puts "a"
  end

  def b
    puts "b"
  end

  def c
    puts "c"
  end

end
p = Play.new
p.fname
