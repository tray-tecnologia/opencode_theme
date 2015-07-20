# encoding: utf-8
require 'thor'
require 'yaml'
YAML::ENGINE.yamler = 'syck' if defined? Syck
require 'abbrev'
require 'base64'
require 'fileutils'
require 'json'
require 'filewatcher'
require 'launchy'
require 'mimemagic'
MimeMagic.add('application/json', extensions: %w(json js), parents: 'text/plain')
MimeMagic.add('application/x-pointplus', extensions: %w(scss), parents: 'text/css')
MimeMagic.add('application/vnd.ms-fontobject', extensions: %w(eot), parents: 'font/opentype')


module OpencodeTheme
  class Cli < Thor
    include Thor::Actions

    IGNORE = %w(config.yml)
    DEFAULT_WHITELIST = %w(configs/ css/ elements/ img/ layouts/ pages/ js/)
    TIMEFORMAT = "%H:%M:%S"

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    desc "configure API_KEY PASSWORD THEME_ID", "Configura o tema que sera modificado"
    def configure(api_key=nil, password=nil, theme_id=nil)
      config = {:api_key => api_key, :password => password, :theme_id => theme_id}
      OpencodeTheme.config = config
      response = OpencodeTheme.check_config
      if response[:success]
        config.merge!(:preview_url => response[:response]['preview'])
        create_file('config.yml', config.to_yaml, :force => true)
        say("Configuration [OK]", :green)
      else
        say("Configuration [FAIL]", :red)
      end
    end

    desc "list", "Lista todos os temas da loja"
    def list
      config = OpencodeTheme.config
      response = OpencodeTheme.list
      if response[:success]
        say("\n")
        response[:response]["themes"].each do |theme|
          color = theme['published'] == "1" ? :green : :red
          say("Theme name:   ", color)
          say("#{theme['name']}\n", color)
          say("Theme ID:     ", color)
          say("#{theme['id']}\n", color)
          say("Theme status: ", color)
          say("#{(theme['published'])}\n\n", color)
        end
      else
        report_error(Time.now, "Could not list now")
      end
    end
  
    desc "clean", "Limpa o cache de arquivos estáticos"
    def clean
      config = OpencodeTheme.config
      response = OpencodeTheme.clean
        if response[:success]
          say("Clean cache [OK]\n",  :green)
        else   
          say("Clean cache [FAIL]",  :red)
        end
      end

    desc "bootstrap API_KEY PASSWORD THEME_NAME THEME_BASE", "Cria um novo tema com o nome informado"
    method_option :master, :type => :boolean, :default => false
    def bootstrap(api_key=nil, password=nil, theme_name='default', theme_base='default')
      OpencodeTheme.config = {:api_key => api_key, :password => password}

      check_config = OpencodeTheme.check_config

      if check_config[:success]
        say("Configuration [OK]", :green)
      else
        report_error(Time.now, "Configuration [FAIL]", check_config[:response])
        return
      end

      response = OpencodeTheme.theme_new(theme_base, theme_name)

      if response[:success]
        say("Create #{theme_name} theme on store", :green)
      else
        report_error(Time.now, "Could not create a new theme", response[:response])
        return
      end

      say("Creating directory named #{theme_name}", :green)
      empty_directory(theme_name)

      say("Saving configuration to #{theme_name}", :green)
      OpencodeTheme.config.merge!(theme_id: response[:response]['theme_id'], preview_url: response[:response]['preview'])
      create_file("#{theme_name}/config.yml", OpencodeTheme.config.to_yaml)

      say("Downloading #{theme_name} assets from Opencode")
      Dir.chdir(theme_name)
      download()
    end

    desc "open", "Abre a loja no navegador"
    def open(*keys)
      if Launchy.open opencode_theme_url
        say("Done.", :green)
      end
    end

    desc "download FILE", "Baixa o arquivo informado ou todos se FILE for omitido"
    method_option :quiet, :type => :boolean, :default => false
    method_option :exclude
    def download(*keys)
      assets = keys.empty? ? OpencodeTheme.asset_list : keys
      if options['exclude']
        assets = assets.delete_if { |asset| asset =~ Regexp.new(options['exclude']) }
      end

      assets.each do |asset|
      asset = URI.decode(asset)       
        download_asset(asset)
        say("#{OpencodeTheme.api_usage} Downloaded: #{asset}", :green) unless options['quiet']
      end
      say("Done.", :green) unless options['quiet']
    end

    desc "upload FILE", "Sobe o arquivo informado ou todos se FILE for omitido"
    method_option :quiet, :type => :boolean, :default => false
    def upload(*keys)
      assets = keys.empty? ? local_assets_list : keys
      assets.each do |asset|
        send_asset("#{asset}", options['quiet'])
      end
      say("Done.", :green) unless options['quiet']
    end

    desc "remove FILE", "Remove um arquivo do tema (apenas se o tema nao estiver publicado)"
    method_option :quiet, :type => :boolean, :default => false
    def remove(*keys)
      keys.each do |key|
        delete_asset(key, options['quiet'])
      end
      say("Done.", :green) unless options['quiet']
    end

    desc "watch", "Baixa e sobe um arquivo sempre que ele for salvo"
    method_option :quiet, :type => :boolean, :default => false
    method_option :keep_files, :type => :boolean, :default => false
    def watch
      watcher do |filename, event|
        filename = filename.gsub("#{Dir.pwd}/", '')
        unless local_assets_list.include?(filename)
          say("Unknown file [#{filename}]", :red)
          next
        end
        action = if [:changed, :new].include?(event)
          :send_asset
        elsif event == :delete
          :delete_asset
        else
          raise NotImplementedError, "Unknown event -- #{event} -- #{filename}"
        end
        send(action, filename, options['quiet'])
      end
    end

    desc "publish", "Publica um tema"
    def publish
      response = OpencodeTheme.publish(config[:theme_id])
      if response[:success]
        say("Publishing Theme [OK]", :green)
      else
        say("Publishing Theme [FAIL]", :red)
      end
    end


    desc "systeminfo", "Mostra informacoes do sistema"
    def systeminfo
      ruby_version = "#{RUBY_VERSION}"
      ruby_version += "-p#{RUBY_PATCHLEVEL}" if RUBY_PATCHLEVEL
      puts "Ruby: v#{ruby_version}"
      puts "Operating System: #{RUBY_PLATFORM}"
      %w(Listen HTTParty Launchy).each do |lib|
        require "#{lib.downcase}/version"
        puts "#{lib}: v" +  Kernel.const_get("#{lib}::VERSION")
      end
    end


protected

    def config
      @config ||= YAML.load_file 'config.yml'
    end

private

    def notify_and_sleep(message)
      say(message, :red)
      OpencodeTheme.sleep
    end

    def binary_file?(path)
     !MimeMagic.by_path(path).text?
    end

    def opencode_theme_url
      config[:preview_url]
    end


    def send_asset(asset, quiet = false)
      if valid_name?(asset)
        return unless valid?(asset)
        data = { key: "/#{asset}" }
        content = File.read("#{asset}")
        if binary_file?(asset) || OpencodeTheme.is_binary_data?(content)
          content = File.open("#{asset}", "rb") { |io| io.read }
          data.merge!(attachment: Base64.encode64(content))
        else
          data.merge!(value: Base64.encode64(content))
        end
        response = show_during("[#{timestamp}] Uploading: #{asset}", quiet) do
          OpencodeTheme.send_asset(data)
        end
        if response.success?
          say("[#{timestamp}] Uploaded: #{asset}", :green) unless quiet
        else
          report_error(Time.now, "Could not upload #{asset}", response)
        end
      end
    end

    def delete_asset(key, quiet=false)
      return unless valid?(key)
      response = show_during("[#{timestamp}] Removing: #{key}", quiet) do
        OpencodeTheme.delete_asset(key)
      end
      if response.success?
        say("[#{timestamp}] Removed: #{key}", :green) unless quiet
      else
        report_error(Time.now, "Could not remove #{key}", response)
      end
    end

    def watcher
      FileWatcher.new(Dir.pwd).watch() do |filename, event|
        yield("#{filename}", event)
      end
    end

    def local_assets_list
      local_files.reject do |p|
        @permitted_files ||= (DEFAULT_WHITELIST | OpencodeTheme.whitelist_files).map{|pattern| Regexp.new(pattern)}
        @permitted_files.none? { |regex| regex =~ p } || OpencodeTheme.ignore_files.any? { |regex| regex =~ p }
      end
    end

    def local_files
      Dir.glob(File.join('**', '*')).reject do |f|
        File.directory?(f)
      end
    end

    def valid?(key)
      return true
      #return true if DEFAULT_WHITELIST.include?(key.split('/').first + "/")
      # say("'#{key}' is not in a valid file for theme uploads", :yellow)
      # say("Files need to be in one of the following subdirectories: #{DEFAULT_WHITELIST.join(' ')}", :yellow)
      # false
    end

    def timestamp(time = Time.now)
      time.strftime(TIMEFORMAT)
    end

     def valid_name?(key)
      name = key.split("/").last
      if name =~ /^[0-9a-zA-Z\-_.]+\.(ttf|eot|svg|woff|css|scss|html|js|jpg|gif|png|json|TTF|EOT|SVG|WOFF|CSS|SCSS|HTML|JS|PNG|GIF|JPG|JSON)$/
        valid =  true
      else
         report_error(Time.now, "INVALID NAME #{name}", key)
      end
      valid      
    end

    def download_asset(key)
      if valid_name?(key)
        return unless valid?(key)
        notify_and_sleep("Approaching limit of API permits. Naptime until more permits become available!") if OpencodeTheme.needs_sleep?
        asset = OpencodeTheme.get_asset(URI.encode(key))
        unless asset['key']
          report_error(Time.now, "Could not download #{key}", asset)
          return
        end
        if asset['content']
         content = Base64.decode64(asset['content'])
         content = content.force_encoding("UTF-8")
          format = "w+b:ISO-8859-1"
        elsif asset['attachment']
          content = Base64.decode64(asset['attachment'])
          format = "w+b"
        end
        FileUtils.mkdir_p(File.dirname(URI.decode(key)))
        File.open(key, format) {|f| f.write content} if content
      end
    end

    def show_during(message = '', quiet = false, &block)
      print(message) unless quiet
      result = yield
      print("\r#{' ' * message.length}\r") unless quiet
      result
    end

    def report_error(time, message, response)
      say("[#{timestamp(time)}] Error: #{message}", :red)
      say("Error Details: #{response}", :yellow)
    end

  end

end
