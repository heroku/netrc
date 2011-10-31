task 'test' do
  $:.unshift "./lib"
  for p in Dir["./test/test_*.rb"]
    require p
  end
end
