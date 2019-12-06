# encoding: utf-8

module Zebra
  module Zpl
    
    module VariableData
      attr_accessor :name, :variable_id
      attr_reader :wants_variable
      
      # Tell this element it should have variable field data
      def variable=(flag)
        @wants_variable = flag
        @variable_id = nil unless flag
      end
    
      # Does this element have variable field data?
      def variable?
        !@variable_id.nil?
      end
      
      def wants_variable?
        @wants_variable
      end
      
      def data=(data)
        if data==:variable
          puts "Field wants variable"
          @wants_variable = true
        end

        @data = data
      end
      
      def data
        @data
      end
      
      def zpl_field_data
        if @variable_id.nil?
          # Static field data
          "^FD#{data}^FS" 
        else
          # Variable field number
          "^FN#{@variable_id}^FS"
        end
      end
      
    end
    
    # Manages a copy of the label with variable data in it.
    class VariableDataElement
      
      attr_accessor :copies, :map
      
      def initialize(label, options={})
        raise ArgumentError.new("Label is required") if label.nil?
        @label = label
        @map = {}
        @copies = options[:copies]
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

          str << if elm.respond_to?(:to_variable_zpl)
            elm.to_variable_zpl(value)
          else
            "^FN#{fn}^FD#{value}^FS\n"
          end
        end
        
        str << "^PQ#{@copies||1}^XZ\n"
        
        str
      end
    end
  end
end