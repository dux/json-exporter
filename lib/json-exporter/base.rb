class JsonExporter
  EXPORTERS ||= {}
  FILTERS   ||= {before:{}, after:{}}
  INFLECTOR ||= Dry::Inflector.new

  class << self
    def define name = nil, &block
      name = name ? "#{INFLECTOR.classify(name)}#{to_s}" : to_s

      EXPORTERS[name] = block
    end

    def export name, opts = nil
      new(name, opts || {}).render
    end

    def before &block
      __define_filter :before, &block
    end

    def after &block
      __define_filter :after, &block
    end

    def __define_filter name, &block
      define_method name do
        super() if self.class != JsonExporter
        instance_exec &block
      end
    end
  end

  ###

  attr_accessor :json, :model, :opts

  alias :response :json

  def initialize model, opts = {}
    if model.is_a?(String) || model.is_a?(Symbol)
      raise ArgumentError, 'model argument is not model instance (it is %s)' % model.class
    end

    opts[:export_depth]  ||= 2 # 2 is default depth. if we encounter nested recursive exports, will go only to depth 2
    opts[:current_depth] ||= 0
    opts[:current_depth] += 1

    @model = model
    @opts  = opts.to_hwia
    @block = __find_exporter
    @json  = {}
  end

  def render
    before
    instance_exec &@block
    after

    @json
  end

  def before; end

  def after; end

  private

  # export object
  # export :org_users, key: :users
  def export name, local_opts = {}
    return if @opts[:current_depth] > @opts[:export_depth]

    if name.is_a?(Symbol)
      name, cmodel = name, @model.send(name)

      if cmodel.respond_to?(:all) && cmodel.respond_to?(:first)
        cmodel = cmodel.all.map { |el| JsonExporter.export(el, @opts.dup) }
      end
    else
      underscored = INFLECTOR.underscore(name.class.to_s).to_sym
      name, cmodel = underscored, name
    end

    @json[name] = if [Array].include?(cmodel.class)
      cmodel
    elsif cmodel.nil?
      nil
    else
      new_opts = local_opts.merge(export_depth: @opts[:export_depth], current_depth: @opts[:current_depth])
      self.class.new(cmodel, new_opts).render
    end
  end

  # add property to exporter
  def property name, data = :_undefined, &block
    if block_given?
      hash_data = {}
      data = instance_exec hash_data, &block
      data = hash_data if hash_data.keys.first
    elsif data == :_undefined
      data = @model.send(name)
    end

    @json[name] = data unless data.nil?
  end
  alias :prop :property

  def __find_exporter version = nil
    base     = INFLECTOR.classify @opts[:exporter] || model.class.to_s
    exporter = self.class.to_s

    self.class.ancestors.map(&:to_s).each do |klass|
      block = EXPORTERS[[base, klass].join] || EXPORTERS[klass]
      return block if block
    end

    raise(%[Exporter for class "#{base}" not found.])
  end
end

