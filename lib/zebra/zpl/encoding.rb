# encoding: utf-8

module Zebra
  module Zpl
    class Encoding
      include VariableData
            
      # Expects EPC, etc.
      def initialize(opts={})
        @opts = opts
        @opts.each_pair { |attribute, value| self.__send__ "#{attribute}=", value }
      end
      
      def to_zpl
        #^RFo,f,b,n,m
        # o = operation [W]rite/[R]read/[S]pecifify access password
        # f = format Ascii, Hex, Epc (see ^RB for EPC)
        # b = password or starting block number
        # n = number of bytes to read or write (not req for A or H)
        # m = Gen2 Memory Bank; [E]pc, [A]uto adjust, 1=EPC, 2=TID, 3=User
        # 
        # ^RFW,H^SN100000000001,1,Y^FS
        
        if variable?
          ''
        else
          "^RFW,H#{zpl_field_data}"
        end
      end
      
      def to_variable_zpl(value)
        "^RFW,H^FD#{value}^FS"
      end
      
    end
  end
end