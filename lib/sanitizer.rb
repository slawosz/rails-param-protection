module RailsParamProtection
  module Sanitizer

    def sanitize!(*args)
      args.each do |arg|
        case arg
        when Hash
          array = arg.to_a.first
          key,value = array
          if value.is_a? Array
            self[key].sanitize!(*value)
          else
            self[key].sanitize!(value)
          end
        else
          self.delete(arg)
        end
      end
      self
    end

    def sanitize_except!(*args)
      self.each_key do |key|
        args.each do |arg|
          case arg
          when Hash
            array = arg.to_a.first
            key,value = array
            if value.is_a?(Array)
              self[key].sanitize_except!(*value)
            else
              self[key].sanitize_except!(value)
            end
            self.sanitize_except!(key)
          else
            unless args.include?(key)
              self.delete(key)
            end
          end
        end
      end
      self
    end

  end
end
