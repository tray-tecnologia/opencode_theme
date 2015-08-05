require_relative '../spec_helper'

describe OpencodeTheme::Cli, :functional do
  
  STORE_ID = '430692'
  FILE_NAME = 'layouts/default.html'
  API_KEY = '11451c354c1f95fe60f80d7672bf184a'
  PASSWORD = '14ae838d9e971465af45b35803b8f0a4'
  
  after(:all) do
    # clearing generated and downloaded files
    FileUtils.rm 'config.yml'
    FileUtils.rm_rf 'default'
  end
  
  context 'Invalid or Inexistent Configuration' do
    it 'does not list when the config is invalid' do
      output = capture(:stdout) { subject.list }
      expect(File.exists? 'config.yml').to eq false
      expect(output).to include 'config.yml does not exist!'
      expect(output).to include 'Error: Could not list now'
      expect(output).to include 'Error Details: {"authentication"=>false}'
    end
    
    it 'does not clean cache when the config is invalid' do
      output = capture(:stdout) { subject.clean }
      expect(File.exists? 'config.yml').to eq false
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
      expect(File.exists? 'config.yml').to eq false
    end
    
    it 'creates config.yml when called with parameters' do
      output = capture(:stdout) { subject.configure API_KEY, PASSWORD }
      expect(output).to include 'Configuration [OK]'
      expect(File.exists? 'config.yml').to eq true
    end
  end
  
  context 'Bootstrap' do
    it 'create new theme' do
      output = capture(:stdout) { subject.bootstrap API_KEY, PASSWORD }
      FileUtils.cd '..'
      expect(output).to include 'Configuration [OK]'
      expect(output).to include 'Create default theme on store'
      expect(output).to include 'Saving configuration to default'
      expect(output).to include 'Downloading default assets from Opencode'
      expect(output).to include "Downloaded: #{ FILE_NAME }"
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
      FileUtils.cd 'default'
      output = capture(:stdout) { subject.clean }
      FileUtils.cd '..'
      expect(output).to include 'Clean cache [OK]'
    end
  end
  
  context 'Download' do
    it 'downloads all files' do
      FileUtils.cd 'default'
      output = capture(:stdout) { subject.download }
      FileUtils.cd '..'
      expect(output).to include 'Downloaded'
      expect(output).to include "Downloaded: #{ FILE_NAME }"
      expect(output).not_to include 'Error'
      expect(output).to include 'Done.'
    end
    
    it 'downloads a single file' do
      FileUtils.cd 'default'
      output = capture(:stdout) { subject.download FILE_NAME }
      FileUtils.cd '..'
      expect(output).to include "Downloaded: #{ FILE_NAME }"
      expect(output).to include 'Done.'
      expect(output).not_to include 'Error'
    end
  end
  
  context 'Upload' do
    it 'uploads all files' do
      FileUtils.cd 'default'
      output = capture(:stdout) { subject.upload }
      FileUtils.cd '..'
      expect(output).to include 'Uploaded'
      expect(output).to include "Uploaded: #{ FILE_NAME }"
      expect(output).not_to include 'Error'
      expect(output).to include 'Done.'
    end
    
    it 'uploads a single file' do
      FileUtils.cd 'default'
      output = capture(:stdout) { subject.upload FILE_NAME }
      FileUtils.cd '..'
      expect(output).to include "Uploaded: #{ FILE_NAME }"
      expect(output).to include 'Done.'
      expect(output).not_to include 'Error'
    end
  end
  
  context 'System Information' do
    let(:output) { capture(:stdout) { subject.systeminfo } }
    
    it 'displays system information' do
      pending 'redmine issue 37576'
      expect(output).not_to be_nil
    end
  end
  
  context 'Help' do
    let(:output) { capture(:stdout) { subject.help } }
    
    it 'displays help about each command' do
      expect(output).to include 'Commands:'
      expect(output).to include 'bootstrap API_KEY PASSWORD THEME_NAME THEME_BASE'
      expect(output).to include 'clean'
      expect(output).to include 'configure API_KEY PASSWORD THEME_ID'
      expect(output).to include 'download FILE'
      expect(output).to include 'help [COMMAND]'
      expect(output).to include 'list'
      expect(output).to include 'open'
      expect(output).to include 'remove FILE'
      expect(output).to include 'systeminfo'
      expect(output).to include 'upload FILE'
      expect(output).to include 'watch'
    end
  end
    
end
