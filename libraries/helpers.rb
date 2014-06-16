module BindZone
  module Helpers
    def render_options(options)
      result = ''
      case options
      when Hash, Mash
        options.each do |key, value|
          result << "%s %s\n" % [key, render_options(value)]
        end
      when Array
        result << "{\n"
        options.each do |value|
          result << "\t" + render_options(value)
        end
        result << '};'
      else
        result << "%s;\n" % [options]
      end
      result
    end
  end
end
