require_relative '../spec_helper'

describe OpencodeTheme::Cli, :functional do
  
  STORE_ID = '430692'
  API_KEY = '11451c354c1f95fe60f80d7672bf184a'
  PASSWORD = '14ae838d9e971465af45b35803b8f0a4'
  THEME_ID = ''
  
  after(:all) do
    # clearing generated and downloaded files
    FileUtils.cd '..'
    FileUtils.rm 'config.yml'
    FileUtils.rm_rf 'default'
  end
  
  context 'Invalid or Inexistent Configuration' do
    it 'does not list when the config is invalid' do
      pending 'redmine issue 37588'
      output = capture(:stdout) { subject.list }
      expect(output).to include '[FAIL]'
    end
  end
  
  context 'Configure' do
    it 'fails to create config.yml file when called with no arguments' do
      pending 'redmine issue 37590'
      output = capture(:stdout) { subject.configure }
      expect(output).to include '[FAIL]'
    end
    
    it 'creates config.yml when called with parameters' do
      output = capture(:stdout) { subject.configure API_KEY, PASSWORD }
      expect(output).to include 'Configuration [OK]'
      expect(File.exists? 'config.yml').to eq true
    end
  end
  
  context 'Bootstrap' do
    after(:context) do
      Dir.chdir '..'
    end
    
    it 'create new theme' do
      output = capture(:stdout) { subject.bootstrap API_KEY, PASSWORD }
      expect(output).to include 'Configuration [OK]'
      expect(output).to include 'Create default theme on store'
      expect(output).to include 'Saving configuration to default'
      expect(output).to include 'Downloading default assets from Opencode'
      expect(output).to include 'Done.'
    end
  end
  
  context 'List' do
    let(:output) { capture(:stdout) { subject.list } }
    
    it 'lists all the themes from the store' do
      output = capture(:stdout) { subject.list }
      expect(output).to include 'Theme name:'
      expect(output).to include 'Theme ID:'
      expect(output).to include 'Theme status:'
    end
  end
    
  context 'Publishing Theme' do
    it 'publishes theme' do
      pending 'redmine issue 36815'
      Dir.chdir 'default'
      output = capture(:stdout) { subject.publish }
      expect(output).not_to include '[FAIL]'
      expect(output).to include '[SUCCESS]'
      Dir.chdir '..'
    end
  end
  
  context 'System Information' do
    let(:output) { capture(:stdout) { subject.systeminfo } }
    
    it 'displays system information' do
      pending 'redmine issue 37576'
      expect(output).not_to be_nil
    end
  end
    
end
