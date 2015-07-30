module OpencodeTheme
  class CliDouble < Cli
    attr_writer :local_files, :mock_config
  
    def configure(api_key=nil, password=nil, theme_id=nil)
      super(api_key, password, theme_id)
    end
  
    def list
      super
    end
  
    def clean
      super
    end
  
    def bootstrap
      super
    end
  
    def open
    
    end
  
    def download
    
    end
  
    def upload
    
    end
  
    def remove
    
    end
  
    def watch
    
    end
    
    def systeminfo
    
    end
  
    ##########################################
    
    no_commands do
      def config
        @mock_config || super
      end
  
      def opencode_theme_url
        super
      end

      def binary_file?(file)
        super
      end
  
      def local_files
        @local_files
      end
    end
  end
end