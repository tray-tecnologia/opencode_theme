require_relative '../spec_helper'

describe OpencodeTheme::Cli, :functional do
  STORE_ID = '430692'
  FILE_NAME = 'layouts/default.html'
  API_KEY = 'abe14f7154762dd43c3e499bab004abd'
  PASSWORD = '2ff62ce74b4d9b7da6e09e1a7d0767c7'
  THEME_NAME = 'TA Test Theme'

  before(:all) do
    # clearing generated and downloaded files
    FileUtils.rm_rf 'config.yml' if File.exist?('config.yml')
    FileUtils.rm_rf THEME_NAME if File.exist?(THEME_NAME)
  end

  after(:all) do
    # deleting created theme
    FileUtils.cd THEME_NAME
    config = YAML.load_file 'config.yml'
    res = OpencodeTheme.theme_delete(config[:theme_id])
    if res[:success]
      puts "  deleted theme #{config[:theme_id]}"
    else
      puts "  THEME #{config[:theme_id]} NOT DELETED! DELETE MANUALLY!"
    end
    FileUtils.cd '..'
    # clearing generated and downloaded files
    FileUtils.rm_rf 'config.yml'
    FileUtils.rm_rf THEME_NAME
  end

  context 'Invalid or Inexistent Configuration' do
    it 'does not list when the config is invalid' do
      output = capture(:stdout) { subject.list }
      expect(File.exist? 'config.yml').to eq false
      expect(output).to include 'config.yml does not exist!'
      expect(output).to include 'Error: Configuration [FAIL]'
      expect(output).to include 'Error Details: necessário autenticação'
    end

    it 'does not clean cache when the config is invalid' do
      output = capture(:stdout) { subject.clean }
      expect(File.exist? 'config.yml').to eq false
      expect(output).to include 'Clean cache [FAIL]'
    end

    it 'does not upload any file when the config is invalid' do
      output = capture(:stdout) { subject.upload }
      expect(output).not_to include 'Uploaded'
      expect(output).to include 'Done.'
    end
  end

  context 'Configure' do
    it 'fails to create config.yml file when called with no arguments' do
      output = capture(:stdout) { subject.configure }
      expect(output).to include 'Configuration [FAIL]'
      expect(File.exist? 'config.yml').to eq false
    end

    it 'fails to create config.yml file when called with inexistent theme_id' do
      output = capture(:stdout) { subject.configure API_KEY, PASSWORD, 214_748_364_7 }
      expect(output).to include 'Configuration [FAIL]'
      expect(File.exist? 'config.yml').to eq false
    end

    it 'fails to create config.yml file when called with invalid theme_id' do
      output = capture(:stdout) { subject.configure API_KEY, PASSWORD, 'aaa' }
      expect(output).to include 'Configuration [FAIL]'
      expect(File.exist? 'config.yml').to eq false
    end

    it 'creates config.yml when called with valid theme_id' do
      output = capture(:stdout) { subject.configure API_KEY, PASSWORD, 1 }
      expect(output).to include 'Configuration [OK]'
      expect(File.exist? 'config.yml').to eq true
    end
  end

  context 'Bootstrap' do
    it 'create new theme' do
      output = capture(:stdout) { subject.bootstrap API_KEY, PASSWORD, THEME_NAME }
      FileUtils.cd '..'
      expect(output).to include 'Configuration [OK]'
      expect(output).to include "Create #{THEME_NAME} theme on store"
      expect(output).to include "Saving configuration to #{THEME_NAME}"
      expect(output).to include "Downloading #{THEME_NAME} assets from Opencode"
      expect(output).to include "Downloaded: #{FILE_NAME}"
      expect(output).to include 'Done.'
    end
  end

  context 'List' do
    it 'lists all the themes from the store' do
      output = capture(:stdout) { subject.list }
      expect(output).to include 'Theme name:'
      expect(output).to include 'Theme ID:'
      expect(output).to include 'Theme status:'
    end
  end

  context 'Cleaning cache' do
    it 'cleans the cache' do
      expect(File.exist? THEME_NAME).to eq true
      FileUtils.cd THEME_NAME
      output = capture(:stdout) { subject.clean }
      FileUtils.cd '..'
      expect(output).to include 'Clean cache [OK]'
    end
  end

  context 'Download' do
    it 'downloads all files' do
      expect(File.exist? THEME_NAME).to eq true
      FileUtils.cd THEME_NAME
      output = capture(:stdout) { subject.download }
      FileUtils.cd '..'
      expect(output).to include 'Downloaded'
      expect(output).to include "Downloaded: #{FILE_NAME}"
      expect(output).not_to include 'Error'
      expect(output).not_to include 'Net::ReadTimeout'
      expect(output).to include 'Done.'
    end

    it 'downloads a single file' do
      expect(File.exist? THEME_NAME).to eq true
      FileUtils.cd THEME_NAME
      output = capture(:stdout) { subject.download FILE_NAME }
      FileUtils.cd '..'
      expect(output).to include "Downloaded: #{FILE_NAME}"
      expect(output).to include 'Done.'
      expect(output).not_to include 'Error'
    end
  end

  context 'Upload' do
    it 'uploads all files' do
      expect(File.exist? THEME_NAME).to eq true
      FileUtils.cd THEME_NAME

      output = capture(:stdout) { subject.upload }
      FileUtils.cd '..'
      expect(output).to include "File uploaded: #{FILE_NAME}"
      expect(output).to include 'Done.'
      expect(output).not_to include 'Error'
    end

    it 'uploads a single file' do
      expect(File.exist? THEME_NAME).to eq true
      FileUtils.cd THEME_NAME
      output = capture(:stdout) { subject.upload FILE_NAME }
      FileUtils.cd '..'
      expect(output).to include "File uploaded: #{FILE_NAME}"
      expect(output).to include 'Done.'
      expect(output).not_to include 'Error'
    end
  end

  context 'System Information' do
    let(:output) { capture(:stdout) { subject.systeminfo } }

    it 'displays system information' do
      expect(output).not_to be_nil
    end
  end

  context 'Help' do
    let(:output) { capture(:stdout) { subject.help } }
    it 'displays help about each command' do
      expect(output).to include 'Commands:'
      expect(output).to include 'new API_KEY PASSWORD THEME_NAME THEME_BASE'
      expect(output).to include 'clean'
      expect(output).to include 'configure API_KEY PASSWORD THEME_ID'
      expect(output).to include 'download FILE'
      expect(output).to include 'help [COMMAND]'
      expect(output).to include 'list'
      expect(output).to include 'open'
      expect(output).to include 'rm FILE'
      expect(output).to include 'systeminfo'
      expect(output).to include 'upload FILE'
      expect(output).to include 'watch'
    end
  end
end
