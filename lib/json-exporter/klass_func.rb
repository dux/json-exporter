# shortcut for JsonExporter.define(:page) {}
# JsonExporter :page do
#   prop :name
# end

# shortcut for JsonExporter.new(Page.first).render
# JsonExporter Page.first

def JsonExporter name_or_object, opts = {}, &block
  if block
    JsonExporter.define name_or_object, &block
  else
    JsonExporter.new(name_or_object, opts).render
  end
end