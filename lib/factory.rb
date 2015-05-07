require "factory/version"

module Factory
  class Factory
    def self.new (*fields, &block)
      raise ArgumentError, "wrong number of arguments (0 for 1+)" if fields.size == 0

      # constant check
      constantName = nil
      if fields[0].class == String
        constantName = fields.shift
        constantPattern = /^[A-Z]/

        raise NameError, "identifier " + constantName + " needs to be constant" unless constantName =~ /^[A-Z]/
      end

      # class
      essence = Class.new do
        # getters / setters
        fields.each do |item|
          item = item.to_s
          raise TypeError, item.to_s + " is not a symbol" if item.class != String && item.class != Symbol

          self.class_eval("def #{item};@#{item};end")
          self.class_eval("def #{item}=(val);@#{item}=val;end")
        end

        # initialize
        define_method :initialize do |*params|
          raise ArgumentError, "factory size differs" if params.size > fields.size

          fields.each_with_index do |item, indx|
            name = item.to_s + "="

            self.send(name, params[indx])
          end
        end

        # brackets getter
        def [] (field)
          name = get_instance_var_name(field)

          self.send(name)
        end

        # brackets setter
        def []= (field, value)
          name = get_instance_var_name(field)

          self.instance_variable_set(name, value)
        end

        # blocks
        self.class_eval(&block) if block_given?

        private
          # check and return instance variable
          def get_instance_var_name (field)
            if field.class == String || field.class == Symbol
              name = ("@" + field.to_s).to_sym
              raise NameError, "no member '" + field.to_s + "' in factory" unless self.instance_variables.include?(name)
            elsif field.class == Fixnum
              name = self.instance_variables[field]
              raise IndexError, "offset " + field.to_s + " too large for factory" unless name
            else
              raise TypeError, "no implicit conversion of " + field.class.to_s + " into Integer"
            end

            name
          end
      end

      # set constant
      self.const_set(constantName, essence) if constantName

      essence
    end
  end
end
