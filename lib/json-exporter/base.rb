class JsonExporter
  EXPORTERS ||= {}
  FILTERS   ||= {before:{}, after:{}}
  INFLECTOR ||= Dry::Inflector.new

  class << self
    def define name = nil, &block
      # if name is given, prepend name, if not, use class name as exporter name
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

    private

    def __define_filter name, &block
      define_method name do
        super() if self.class != JsonExporter
        instance_exec &block
      end
    end
  end

  ###

  attr_accessor :json, :model

  alias :response :json

  def initialize model, opts = {}
    if [String, Symbol].include?(model.class)
      raise ArgumentError, 'model argument is not model instance (it is a %s)' % model.class
    end

    opts[:export_depth]  ||= 2 # 2 is default depth. if we encounter nested recursive exports, will go only to depth 2
    opts[:current_depth] ||= 0
    opts[:current_depth] += 1

    @model = model
    @opts  = opts.to_hwia
    @block = __find_exporter
    @json  = {}
  end

  def opts name = nil
    if name
      if @opts[name]
        block_given? ? yield : true
      end
    else
      @opts
    end
  end

  def render
    before
    instance_exec &@block
    after

    @json
  end

  def merge data
    data.each {|k,v| json[k] = v }
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

      if cmodel.class.to_s.include?('Array')
        cmodel = cmodel.map { |el| self.class.export(el, __opts) }
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
      self.class.new(cmodel, __opts(local_opts)).render
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

    raise %[Exporter for class "#{base}" not found.]
  end

  def __opts start = {}
    start.merge(
      export_depth: @opts[:export_depth],
      current_depth: @opts[:current_depth]
    )
  end
end

