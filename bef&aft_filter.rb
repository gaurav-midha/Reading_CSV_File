module Filter
  def self.included(cls)
    cls.extend ClassMethods
  end
  module ClassMethods
    def find_except(name)
      cls_var = class_variables
      bef_name = "@@bef_met_" + name.to_s
      aft_name = "@@aft_met_" + name.to_s 
      if !(cls_var.include?(bef_name))
        send :class_variable_set, "#{bef_name}", []
      end
      if !(cls_var.include?(aft_name))
        send :class_variable_set, "#{aft_name}", []
      end
      cls_var = []
      cls_var << bef_name
      cls_var << aft_name
      cls_var.each do |var|
        if /@@bef_met_/.match(var)
          elem = "@@bef_met_" + name.to_s
          src1 = "@@bef_except_elem"
          src2 = "@@bef_only_elem"
        else
          elem = "@@aft_met_" + name.to_s
          src1 = "@@after_except_elem"
          src2 = "@@after_only_elem"
        end
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
                begin
                  new_ary = send :class_variable_get, "#{elem}"
                rescue
                  new_ary = []
                end
                new_ary << key.to_s
                send :class_variable_set, "#{elem}", new_ary
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
                begin
                  new_ary = send :class_variable_get, "#{elem}"
                rescue
                  new_ary = []
                end
                new_ary << key.to_s
                send :class_variable_set, "#{elem}", new_ary
              end
            end 
          end   #if hash.class == Hash
        end  
      end       #cls_var.each
    end
    def method_added(name)
      if /hook/.match(name.to_s) or method_defined?("#{name}_without_hook") or ["before_method","after_method"].include?(name.to_s)
       return
      end
      find_except(name)
      bef_name = "@@bef_met_" + name.to_s
      aft_name = "@@aft_met_" + name.to_s
      begin
        bef = send :class_variable_get, "#{bef_name}"
      rescue
        bef = []
      end
      begin
        aft = send :class_variable_get, "#{aft_name}"
      rescue
        aft = []
      end
      if bef.include?(name.to_s) or aft.include?(name.to_s)
        return
      end
      hook = "def #{name}_hook \n #puts \"#{name}\" \n hook_before1(\"#{name}\") \n #{name}_without_hook() \n hook_after1(\"#{name}\") \n end"
      self.class_eval(hook)
      a1 = "alias #{name}_without_hook #{name}"
      self.class_eval(a1)
      a2 = "alias #{name} #{name}_hook"
      self.class_eval(a2)
    end

    def before_method(*args)
     arr = []
     cal_met = args.first 
     args.each do |elem|        
      if elem.class == Hash
        if elem.has_key?(:only)
          h = {}
          h[cal_met] = elem[:except]
          begin
            arr = send :class_variable_get, "@@bef_only_elem"
            arr << h
          rescue
            send :class_variable_set, "@@bef_only_elem", []
            arr = send :class_variable_get, "@@bef_only_elem"
            arr << h
          end
        elsif elem.has_key?(:except)
          h = {}
          h[cal_met] = elem[:except]
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
      end
     end
    end
    def after_method(*args)
      arr = []
      cal_met = args.first 
      args.each do |elem|       
        if elem.class == Hash
          if elem.has_key?(:only)
            h = {}
            h[cal_met] = elem[:only]
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
          h[cal_met] = elem[:except]
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
        end
      end
    end
end 
    def hook_before1(name)
      bef_name = "@@bef_met_" + name
      begin
        bef = self.class.send :class_variable_get, "#{bef_name}"
      rescue
        bef = [] 
      end
      bef.each do |met|
       send met 
      end                    
    end

    def hook_after1(name)
      aft_name = "@@aft_met_" + name
      begin
        aft = self.class.send :class_variable_get, "#{aft_name}"
      rescue
        aft = [] 
      end
      aft.each {|met| send met }  
    end
end
class Play
  include Filter
  before_method "a", :only=>["fname"] 
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
p.c
p.fname
p.a
Play.class_variables.each do |elem|
  p Play.send elem
end
