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
MimeMagic.add('application/x-pointplus', extensions: %w(scss styl), parents: 'text/css')
MimeMagic.add('application/font-woff2', extensions: %w(woff2), parents: 'font/opentype')
MimeMagic.add('application/vnd.ms-fontobject', extensions: %w(eot), parents: 'font/opentype')

module OpencodeTheme
  class Cli < Thor
    include Thor::Actions

    IGNORE = %w(config.yml)
    DEFAULT_WHITELIST = %w(configs/ css/ elements/ img/ layouts/ pages/ js/)
    TIMEFORMAT = '%H:%M:%S'

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    map 'new' => :bootstrap
    map 'rm' => :remove

    desc 'configure API_KEY PASSWORD THEME_ID', 'Configura o tema que sera modificado'
    def configure(api_key = nil, password = nil, theme_id = nil)
      config = { api_key: api_key, password: password, theme_id: theme_id }

      if api_key.nil? || password.nil? || theme_id.nil?
        response = {}
        response["message"] = 'necessário informar api_key e password e theme_id.'
        return report_error(Time.now, 'Configuration [FAIL]', response)
      end
      OpencodeTheme.config = config

      response = OpencodeTheme.check_config
      if response[:success]
        config.merge!(preview_url: response[:response]['preview'])
        create_file('config.yml', config.to_yaml, force: true)
        say('Configuration [OK]', :green)
      else
        report_error(Time.now, 'Configuration [FAIL]', response[:response])
      end
    end

    desc 'list', 'Lista todos os temas da loja'
    def list
      config = OpencodeTheme.config
      response = OpencodeTheme.list
    if response[:response]["authentication"] == false
      response = {}
      response["message"] = 'necessário autenticação'
      return report_error(Time.now, 'Configuration [FAIL]', response)
    end

      if response[:success]
        say("\n")
        response[:response]['themes'].each do |theme|
          color = theme['published'] == '1' ? :green : :red
          say('Theme name:   ', color)
          say("#{theme['name']}\n", color)
          say('Theme ID:     ', color)
          say("#{theme['id']}\n", color)
          say('Theme status: ', color)
          say("#{(theme['published'])}\n\n", color)
        end
      else
        report_error(Time.now, 'Could not list now', response[:response])
      end
    end

    desc 'clean', 'Limpa o cache de arquivos estáticos'

    def clean
      config = OpencodeTheme.config
      response = OpencodeTheme.clean
      if response[:success]
        say('Clean cache [OK]\n', :green)
      else
        report_error(Time.now, 'Clean cache [FAIL]', response[:response])
      end
    end

    desc 'new API_KEY PASSWORD THEME_NAME THEME_BASE', 'Cria um novo tema com o nome informado'
    method_option :master, type: :boolean, default: false
    def bootstrap(api_key = nil, password = nil, theme_name = 'default', theme_base = 'default')
      OpencodeTheme.config = { api_key: api_key, password: password }
      check_config = OpencodeTheme.check_config

      if check_config[:success]
        say('Configuration [OK]', :green)
      else
        report_error(Time.now, 'Configuration [FAIL]', check_config[:response])
        return
      end

      response = OpencodeTheme.theme_new(theme_base, theme_name)

      if response[:success]
        say("Create #{theme_name} theme on store", :green)
      else
        report_error(Time.now, 'Could not create a new theme', response[:response])
        return
      end

      say("Creating directory named #{theme_name}", :green)
      empty_directory(theme_name)

      say("Saving configuration to #{theme_name}", :green)
      OpencodeTheme.config.merge!(theme_id: response[:response]['theme_id'], preview_url: response[:response]['preview'])
      create_file("#{theme_name}/config.yml", OpencodeTheme.config.to_yaml)

      say("Downloading #{theme_name} assets from Opencode")
      Dir.chdir(theme_name)
      download
    end

    desc 'open', 'Abre a loja no navegador'
    def open(*keys)
      if Launchy.open opencode_theme_url
        say('Done.', :green)
      end
    end

    desc 'download FILE', 'Baixa o arquivo informado ou todos se FILE for omitido'
    method_option :quiet, type: :boolean, default: false
    method_option :exclude
    def download(*keys)
      assets = keys.empty? ? OpencodeTheme.asset_list : keys
      if assets.is_a? String
        return report_error(Time.now, "List Could not download", JSON.parse(assets))
      end
      if options['exclude']
        assets = assets.delete_if { |asset| asset =~ Regexp.new(options['exclude']) }
      end
      assets.each do |asset|
        asset = URI.decode(asset)
        begin
          download = download_asset(asset)
          if download
            say("#{OpencodeTheme.api_usage} Downloaded: #{asset}", :green) unless options['quiet'] || !download
            say('Done.', :green) unless options['quiet']
          end
        rescue
          say("Error: #{asset}", :red) unless options['quiet']
        end
      end
    end

    desc 'upload FILE', 'Sobe o arquivo informado ou todos se FILE for omitido'
    method_option :quiet, type: :boolean, default: false
    def upload(*keys)
      assets = keys.empty? ? local_assets_list : keys
      assets.each do |asset|
        send_asset("#{asset}", options['quiet'])
      end
      say('Done.', :green) unless options['quiet']
    end

    desc 'rm FILE', 'Remove um arquivo do tema (apenas se o tema nao estiver publicado)'
    method_option :quiet, type: :boolean, default: false
    def remove(*keys)
      keys.each do |key|
        delete_asset(key, options['quiet'])
      end
      say('Done.', :green) unless options['quiet']
    end

    desc 'watch', 'Baixa e sobe um arquivo sempre que ele for salvo'
    method_option :quiet, type: :boolean, default: false
    method_option :keep_files, type: :boolean, default: false


    # def watch
    #   watcher do |filename, event|
    #     filename = filename.gsub("#{Dir.pwd}/", '')
    #     unless local_assets_list.include?(filename)
    #       say("Unknown file [#{filename}]", :red)
    #       next
    #     end
    #     action = if [:changed, :new].include?(event)
    #                 :send_asset
    #     elsif event == :delete
    #       :delete_asset
    #     else
    #       raise NotImplementedError, "Unknown event -- #{event} -- #{filename}"
    #     end
    #     send(action, filename, options['quiet'])
    #   end
    # end
    def watch
      watcher do |filename, event|
        filename = filename.gsub("#{Dir.pwd}/", '')
      if is_file?(filename)

        action = if [:changed, :new].include?(event)
          :send_asset
        elsif event == :delete
          :delete_asset
        else
          say("This is not file [#{filename}]", :blue)
          raise NotImplementedError, "Unknown event -- #{event} -- #{filename}"
        end
        send(action, filename, options['quiet'])
      else
        next
      end


      end
    end

    desc 'systeminfo', 'Mostra informacoes do sistema'
    def systeminfo
      ruby_version = "#{RUBY_VERSION}"
      ruby_version += "-p#{RUBY_PATCHLEVEL}" if RUBY_PATCHLEVEL
      puts "Ruby: v#{ruby_version}"
      puts "OpencodeTheme: v:" + OpencodeTheme::VERSION

      puts "Operating System: #{RUBY_PLATFORM}"
      %w(HTTParty Launchy).each do |lib|
        require "#{lib.downcase}/version"
        puts "#{lib}: v" + Kernel.const_get("#{lib}::VERSION")
      end
    end

    protected

    def is_file?(filename)
      !FileTest.directory?(filename)
    end

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
        return unless is_file?(asset)
        return unless valid_name?(asset)
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
          say("[#{timestamp}] File uploaded: #{asset}", :green) unless quiet
        else
          report_error(Time.now, "Could not upload #{asset}", response)
        end
      end
    end

    def temporary_file?(asset)
      false unless asset.include?('~')
    end

    def delete_asset(key, quiet = false)
      return say("[#{timestamp}] Folder removed/rename: #{key}", :green) unless key.include?('.')
      return exec_delete_file(key) if valid_name?(key)
    end

    def exec_delete_file(key, quiet = false)
      response = show_during("[#{timestamp}] Removing: #{key}", quiet) do
        OpencodeTheme.delete_asset(key)
      end
      if response.success?
        say("[#{timestamp}] File removed: #{key} ", :green) unless quiet
      else
        report_error(Time.now, "Could not remove #{key}", response)
      end
    end

    def watcher
      FileWatcher.new(Dir.pwd).watch do |filename, event|
        yield("#{filename}", event)
      end
    end

    def local_assets_list
      local_files.reject do |p|
        @permitted_files ||= (DEFAULT_WHITELIST | OpencodeTheme.whitelist_files).map{ |pattern| Regexp.new(pattern)}
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
      return if temporary_file?(key)
      name = key.split('/').last
      if name =~ /^[0-9a-zA-Z\-_.]+\.(ttf|eot|svg|woff|woff2|css|scss|styl|html|js|jpg|gif|png|json|TTF|EOT|SVG|WOFF|WOFF2|CSS|SCSS|STYL|HTML|JS|PNG|GIF|JPG|JSON)$/
        valid =  true
      else
        response = {}
        response["message"] = 'verifique as regras de nome de arquivos:'
        response["more_info"] = 'https://sites.google.com/a/tray.net.br/tecnologia/open-code/api?pli=1#00313'
        report_error(Time.now, "Invalid name: #{name}", response)
      end
      valid
    end

    def download_asset(key)
      if valid_name?(key)
        return unless valid?(key)
        notify_and_sleep('Approaching limit of API permits. Naptime until more permits become available!') if OpencodeTheme.needs_sleep?
        response = OpencodeTheme.get_asset(URI.encode(key))
        unless response['key']
          report_error(Time.now, "Could not download #{key}", response)
          return false
        end
        if response['content']
          content = Base64.decode64(response['content'])
          content = content.force_encoding('ISO-8859-1')
          format = 'w+b:ISO-8859-1'
        elsif response['attachment']
          content = Base64.decode64(response['attachment'])
          format = 'w+b'
        end
        FileUtils.mkdir_p(File.dirname(URI.decode(key)))
        File.open(key, format) { |f| f.write content } if content
      end
    end

    def show_during(message = '', quiet = false, &block)
      print(message) unless quiet
      result = yield
      print("\r#{' ' * message.length}\r") unless quiet
      result
    end

    def report_error(time, message, response)
      say("[#{timestamp(time)}] Error: #{message}", :red)  if message
      if response
        message_details = response["message"]
        message_details = "#{message_details} \n #{response["more_info"]}" if !response["more_info"].nil?
        say("Error Details: #{message_details}", :yellow)
      end
    end
  end
end
