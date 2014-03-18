guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

guard 'minitest' do
  watch(%r|^test/test_(.*)\.rb|){|m| "test/test_#{m[1]}.rb"}
  watch(%r|^lib/*\.rb|){'test'}
end
