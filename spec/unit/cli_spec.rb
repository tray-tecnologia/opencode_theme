require_relative '../spec_helper'
require_relative 'cli_double'

describe 'Cli' do
  
  before do
    @cli = OpencodeTheme::CliDouble.new
    OpencodeTheme.config = {}
  end
    
  it 'should report binary files as binary' do
    extensions = %w(png gif jpg jpeg eot ttf woff otf swf ico pdf)
    extensions.each do |ext|
      expect(@cli.binary_file? "hello.#{ext}").to eq(true), ext
    end
  end

  it 'should not report text based files as binary' do
    expect(@cli.binary_file? 'style.css').to eq false
    expect(@cli.binary_file? 'application.js').to eq false
    expect(@cli.binary_file? 'settings_data.json').to eq false
  end
  
end
