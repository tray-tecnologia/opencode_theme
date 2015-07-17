require_relative '../spec_helper'

describe OpencodeTheme::Cli, :functional do
  
  STORE_ID = '430692'
  API_KEY = '11451c354c1f95fe60f80d7672bf184a'
  PASSWORD = '14ae838d9e971465af45b35803b8f0a4'
  THEME_ID = ''
  
  before do
    
  end
  
  after(:context) do
    FileUtils.rm 'config.yml'
  end
    
  context 'Configure' do
    it 'fails to create config.yml file when called with no arguments' do
      output = capture(:stdout) { subject.configure }
      expect(output).to include '[FAIL]'
    end
    
    it 'creates config.yml when called with parameters' do
      output = capture(:stdout) { subject.configure API_KEY, PASSWORD }
      expect(output).to include 'Configuration [OK]'
      # => check for yml file here
    end
  end
  
  context 'List' do
    let(:output) { capture(:stdout) { subject.list } }
    
    it 'lists all the themes from the store' do
      expect(output).to be_nil
    end
  end
    
  context 'Publishing Theme' do
    let(:output) { capture(:stdout) { subject.publish } }
    
    it 'publishes theme' do
      expect(output).not_to include '[FAIL]'
      expect(output).to include '[SUCCESS]'
    end
  end
  
  context 'System Information' do
    let(:output) { capture(:stdout) { subject.systeminfo } }
    
    it 'displays system information' do
      expect(output).not_to be_nil
    end
  end
    
end
