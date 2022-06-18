class JsonExporter
  EXPORTERS ||= {}
  FILTERS   ||= {before:{}, after:{}}
  OPTS      ||= {}
  INFLECTOR ||= Dry::Inflector.new

  class << self
    def define *args, &block
      if args.first.is_a?(Hash)
        name, opts = nil, args[0]
      else
        name, opts = args[0], args[1]
      end

      name   = name ? INFLECTOR.classify(name.to_s) : to_s
      opts ||= {}

      EXPORTERS[name] = block
    end

    def export name, opts = nil
      new(name, opts || {}).render
    end

    def disable_wia!
      OPTS[:wia] = false
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
    @json  = OPTS[:wia] == false ? {} : {}.to_hwia
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
      underscore = INFLECTOR.underscore(name.class.to_s).to_sym
      name, cmodel = underscore, name
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
    exporter = if @opts[:exporter]
      INFLECTOR.classify(@opts[:exporter].to_s)
    elsif self.class == JsonExporter
      model.class
    else
      self.class
    end

    EXPORTERS[exporter.to_s] ||
    EXPORTERS[model.class.to_s] ||
    raise('Exporter "%s" (:%s) not found' % [exporter, INFLECTOR.underscore(exporter.to_s)])
  end
end

