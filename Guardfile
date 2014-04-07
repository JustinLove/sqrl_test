guard 'process',
    :name => 'web',
    :command => 'foreman start web' do
  watch(%r{lib/.+\.rb})
  watch('Guardfile')
  watch('Procfile')
end
