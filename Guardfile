# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', :version => 2 do
  watch(/^spec\/.+_spec\.rb$/)
  watch(/^lib\/(.+)\.rb$/) { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/helper.rb')  { 'spec/' }
  watch('spec/data/.+')    { 'spec/' }
end
