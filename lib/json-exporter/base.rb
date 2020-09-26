class JsonExporter
  EXPORTERS ||= {}
  FILTERS   ||= {}

  attr_accessor :response, :user, :model, :meta

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

    def filter &block
      FILTERS[to_s] = block
    end
  end

  ###

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
    instance_exec &@block
    exporter_apply_filters
    @opts.compact ? @response.compact : @response
  end

  def version version_num=nil, &block
    return @opts.version unless version_num

    if block && @opts.version >= version_num
      instance_exec &block
    end
  end

  private

  # export object
  def export name
    return if @opts[:current_depth] > @opts[:depth]

    if name.is_a?(Symbol)
      name, cmodel = name, @model.send(name)
    else
      name, cmodel = name.class.to_s.underscore.to_sym, name
    end

    @response[name] =
      if [Array].include?(cmodel.class)
        cmodel
      else
        JsonExporter.export(cmodel, @opts)
      end
  end

  # add property to exporter
  def property name, data=:_undefined
    if block_given?
      data = yield
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

  def exporter_apply_filters
    for klass in self.class.ancestors.reverse.map(&:to_s)
      if filter = FILTERS[klass]
        instance_exec(&filter) if filter
      end
    end
  end
end

