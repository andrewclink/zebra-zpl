# encoding: utf-8

module Zebra
  module Zpl
    class VariableData
      
      attr_accessor :copies, :map
      
      def initialize(label, options={})
        raise ArgumentError.new("Label is required") if label.nil?
        @label = label
        @map = {}
      end
      
      def []=(vname, value)
        @map[vname] = value.to_s
      end
      
      def [](vname)
        @map[vname]
      end
      
      def to_zpl
        str = ''
        str << "^XA^XFR:#{@label.filename}^FS\n"
        @label.variable_elements.each do |vname, elm|
          # Get the variable ID to use as a field number
          value = map[vname] || ''
          fn = elm.variable_id

          str << "^FN#{fn}^FD#{value}^FS\n"
        end
        
        str << "^PQ#{@copies}^XZ\n"
        
        str
      end
    end
  end
end