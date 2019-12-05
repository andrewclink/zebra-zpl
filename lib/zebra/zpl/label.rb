# encoding: utf-8

module Zebra
  module Zpl
    class Label
      class InvalidPrintSpeedError     < StandardError; end
      class InvalidPrintDensityError   < StandardError; end
      class PrintSpeedNotInformedError < StandardError; end

      attr_writer :copies
      attr_reader :elements, :variable_elements, :variable_count, :tempfile
      attr_accessor :filename, :width, :length, :print_speed, :variables

      def initialize(options = {})
        @filename = "tmp#{Time.now.to_i.to_s[-4..-1]}"
        options.each_pair { |key, value| self.__send__("#{key}=", value) if self.respond_to?("#{key}=") }
        @variable_count = 0
        @variable_elements = {}
        @variables = []
        @elements = []
      end

      def print_speed=(s)
        raise InvalidPrintSpeedError unless (0..6).include?(s)
        @print_speed = s
      end

      def copies
        @copies || 1
      end

      def <<(element)
        element.width = self.width if element.respond_to?("width=") && element.width.nil?
        
        # Support variable text elements
        if element.respond_to?(:variable?) && element.wants_variable? && element.variable_id.nil?
          # Pre-increment and assign a ^FN
          @variable_count += 1
          element.variable_id = @variable_count
          puts "Assigned FN #{element.variable_id}"

          # Save for later
          raise ArgumentError('Variable elements must have a name') if element.name.nil?
          @variable_elements[element.name] = element
        end
        
        elements << element
      end
      
      def with_variable_data(&block)
        vardata = VariableData.new(self)
        yield(vardata)
        @variables << vardata
      end

      def dump_contents(io = STDOUT)
        check_required_configurations
        # Start format
        io << "^XA"
        io << "^DFR:#{@filename}.ZPL^FS"
        # ^LL<label height in dots>,<space between labels in dots>
        # io << "^LL#{length},#{gap}\n" if length && gap
        io << "^LL#{length}" if length
        # ^LH<label home - x,y coordinates of top left label>
        io << "^LH0,0"
        # ^LS<shift the label to the left(or right)>
        io << "^LS10"
        # ^PW<label width in dots>
        io << "^PW#{width}" if width
        # Print Rate(speed) (^PR command)
        io << "^PR#{print_speed}"
        # Density (D command) "Carried over from EPL, does this exist in ZPL ????"
        # io << "D#{print_density}\n" if print_density

        # TEST ZPL (comment everything else out)...
        # io << "^XA^WD*:*.FNT*^XZ"
        # TEST ZPL SEGMENT
        # io << "^WD*:*.FNT*"
        # TEST AND GET CONFIGS
        # io << "^HH"

        elements.each do |element|
          io << element.to_zpl
        end
        # Specify how many copies to print
        io << "^PQ#{copies}"
        # End format
        io << "^XZ"
        
        @variables.each do |vardata|
          puts "Appending vardata:  #{vardata.map.inspect}"
          vardata.map.each do |vname, value|
            elm = @variable_elements[vname]
            fn = elm.variable_id
            puts "-> FN#{fn} = #{value}"
          end
          
          io << vardata.to_zpl
        end
      end

      def persist
        tempfile = Tempfile.new "zebra_label"
        dump_contents tempfile
        tempfile.close
        @tempfile = tempfile
        tempfile
      end

      def persisted?
        !!self.tempfile
      end
      
      private

      def check_required_configurations
        raise PrintSpeedNotInformedError unless print_speed
      end
    end
  end
end
