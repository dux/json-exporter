class JsonExporter
  EXPORTERS ||= {}
  FILTERS   ||= {b:{}, a:{}}

  class << self
    def define *args, &block
      if args.first.is_a?(Hash)
        name, opts = nil, args[0]
      else
        name, opts = args[0], args[1]
      end

      name   = name ? name.to_s.classify : to_s
      opts ||= {}

      EXPORTERS[name] = block
    end

    def export name, opts={}
      new(name, opts).render
    end

    def before &block
      FILTERS[:b][to_s] = block
    end

    def filter &block
      FILTERS[:a][to_s] = block
    end
    alias :after :filter
  end

  ###

  attr_accessor :response, :user, :model, :opts

  def initialize model, opts={}
    if model.is_a?(String) || model.is_a?(Symbol)
      raise ArgumentError, 'model argument is not model instance (it is %s)' % model.class
    end

    opts[:version] ||= opts.delete(:v) || 1

    if opts.class == Hash
      opts = opts.to_hwia :version, :user, :depth, :current_depth, :exporter, :meta, :wia, :compact
    end

    opts.meta          ||= {}
    opts.depth         ||= 2 # 2 is default depth
    opts.current_depth ||= 0
    opts.current_depth += 1

    @model    = model
    @user     = opts[:user]
    @opts     = opts
    @meta     = opts.wia ? opts.meta.to_hwia : opts.meta
    @block    = exporter_find_class
    @response = opts.wia ? {}.to_hwia : {}
  end

  def render
    exporter_apply_filters :b
    instance_exec &@block
    exporter_apply_filters :a

    @opts.compact ? @response.compact : @response
  end

  def version version_num=nil, &block
    return @opts.version unless version_num

    if block && @opts.version >= version_num
      instance_exec &block
    end
  end

  def meta arg = nil
    if arg
      if !block_given?
        raise ArgumentError.new('Block not given for meta with param')
      elsif @meta[arg]
        yield
      end
    else
      @meta
    end
  end

  private

  # export object
  # export :org_users, key: :users
  def export name, opts = {}
    return if @opts[:current_depth] > @opts[:depth]

    if name.is_a?(Symbol)
      name, cmodel = name, @model.send(name)

      if cmodel.respond_to?(:all) && cmodel.respond_to?(:first)
        cmodel = cmodel.all.map { |el| JsonExporter.export(el, @opts.dup) }
      end
    else
      name, cmodel = name.class.to_s.underscore.to_sym, name
    end

    @response[opts[:key] || name] =
      if [Array].include?(cmodel.class)
        cmodel
      elsif cmodel.nil?
        nil
      else
        JsonExporter.export(cmodel, @opts)
      end
  end

  # add property to exporter
  def property name, data=:_undefined
    if block_given?
      hash_data = {}
      data = yield hash_data
      data = hash_data if hash_data.keys.first
    elsif data == :_undefined
      data = @model.send(name)
    end

    @response[name] = data unless data.nil?
  end
  alias :prop :property

  # finds versioned exporter
  def exporter_find_class version=nil
    exporter =
    if self.class == JsonExporter
      # JsonExporter.define User do
      @opts.exporter ? @opts.exporter.to_s.classify : model.class
    else
      # class FooExporter< JsonExporter
      self.class
    end

    EXPORTERS[exporter.to_s] || raise('Exporter "%s" (:%s) not found' % [exporter, exporter.to_s.underscore])
  end

  def exporter_apply_filters kind
    for klass in self.class.ancestors.reverse.map(&:to_s)
      if filter = FILTERS[kind][klass]
        instance_exec(&filter) if filter
      end
    end
  end

  def merge object
    object.each do |k, v|
      prop k.to_sym, v
    end
  end
end

