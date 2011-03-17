module Filter
  def self.included(cls)
    cls.extend ClassMethods
  end
  module ClassMethods
    def find_except(name,filt)
      ary_var = []   
        if /bef/.match(filt)
          src1 = "@@bef_except_elem"
          src2 = "@@bef_only_elem"
      else
          src1 = "@@after_except_elem"
          src2 = "@@after_only_elem"
        end
          elem ||= [] 
        begin
          arr = send :class_variable_get, "#{src1}"
        rescue
          send :class_variable_set, "#{src1}", []
          arr = []
        end
        arr.each do |hash|
          if hash.class == Hash
            hash.each do |key,val|
              if !(val.include?(name.to_s))
                elem << key.to_s               
              end
            end 
          end   #if hash.class == Hash
        end     
        begin
          arr = send :class_variable_get, "#{src2}"
        rescue
          send :class_variable_set, "#{src2}", []
          arr = []
        end
        arr.each do |hash| 
          if hash.class == Hash
            hash.each do |key,val|
              if (val.class == Array) && (val.include?(name.to_s))
                elem << key.to_s
              end
            end 
          end   #if hash.class == Hash
        end  
       return elem
    end

    def method_added(name)

      if /hook/.match(name.to_s) or method_defined?("#{name}_without_hook") or ["before_method","after_method"].include?(name.to_s)
       return
      end
       bef = find_except(name,"before")
       aft = find_except(name,"after")
      if bef.include?(name.to_s) or aft.include?(name.to_s)
        return
      end
      hook = "def #{name}_hook \n bef = self.class.find_except(\"#{name}\",\"before\") \n bef.each{|elem| send elem} \n #{name}_without_hook() \n aft = self.class.find_except(\"#{name}\",\"after\") \n aft.each{|elem| send elem} \n end"
      self.class_eval(hook)
      a1 = "alias #{name}_without_hook #{name}"
      self.class_eval(a1)
      a2 = "alias #{name} #{name}_hook"
      self.class_eval(a2)
    end

    def before_method(*args)
     arr = []
     cal_met = []
     flag = 0
     args.each do |elem|        
      if elem.class == Hash
        if elem.has_key?(:only)
          flag = 1
          h = {}
          cal_met.each do |cal_met1|
           h[cal_met1] = elem[:only]
          end
          begin
            arr = send :class_variable_get, "@@bef_only_elem"
            arr << h
          rescue
            send :class_variable_set, "@@bef_only_elem", []
            arr = send :class_variable_get, "@@bef_only_elem"
            arr << h
          end
        elsif elem.has_key?(:except)
          flag = 1
          h = {}
          cal_met.each do |cal_met1|
           h[cal_met1] = elem[:except]
          end
          begin
            arr = send :class_variable_get, "@@bef_except_elem"
            arr << h
          rescue
            send :class_variable_set, "@@bef_except_elem", []
            arr = send :class_variable_get, "@@bef_except_elem"
            arr << h
          end
        else
          abort("undefine attributes send to method before")
        end
      else
        cal_met << elem
      end
     end
     if flag == 0
       h = {}
       cal_met.each do |cal_met1|
        h[cal_met1] = []
       end
       begin
         arr = send :class_variable_get, "@@bef_except_elem"
         arr << h
       rescue
         send :class_variable_set, "@@bef_except_elem", []
         arr = send :class_variable_get, "@@bef_except_elem"
         arr << h
       end
     end
    end
    def after_method(*args)
      arr = []
      flag = 0
      cal_met = []
      args.each do |elem|       
        if elem.class == Hash
          if elem.has_key?(:only)
            h = {}
            flag = 1            
            cal_met.each do |cal_met1|
             h[cal_met1] = elem[:only]
            end
            begin
              arr = send :class_variable_get, "@@after_only_elem"
              arr << h
            rescue
              send :class_variable_set, "@@after_only_elem", []
              arr = send :class_variable_get, "@@after_only_elem"
              arr << h
            end
          elsif elem.has_key?(:except)
          h = {}
          flag = 1
          cal_met.each do |cal_met1|
           h[cal_met1] = elem[:except]
          end
          begin
            arr = send :class_variable_get, "@@after_except_elem"
            arr << h
          rescue
            send :class_variable_set, "@@after_except_elem", []
            arr = send :class_variable_get, "@@after_except_elem"
            arr << h
          end
          else
            abort("undefine attributes send to method before")
          end
        else
          cal_met << elem
        end
      end
      if flag == 0
       h = {}
       cal_met.each do |cal_met1|
        h[cal_met1] = []
       end
       begin
         arr = send :class_variable_get, "@@after_except_elem"
         arr << h
       rescue
         send :class_variable_set, "@@after_except_elem", []
         arr = send :class_variable_get, "@@after_except_elem"
         arr << h
       end
      end
    end
  end 
end
class Play
  include Filter
  before_method "a", "c", :only=>["fname"] 
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
