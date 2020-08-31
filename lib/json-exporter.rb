require 'hash_wia'

class JsonExporter
  EXPORTERS ||= {
    __filter: proc {}
  }

  attr_accessor :response, :user, :model, :version

  class << self
    def define name, opts={}, &block
      version = opts.delete(:version) || opts.delete(:v) || 1
      EXPORTERS[version] ||= {}
      EXPORTERS[version][name.to_s.classify] = block
    end

    def export name, opts={}
      new(name, opts).render
    end

    def filter &block
      EXPORTERS[:__filter] = block
    end
  end

  ###

  def initialize model, opts={}
    if model.is_a?(String) || model.is_a?(Symbol)
      raise ArgumentError, 'model argument is not model instance (it is %s)' % model.class
    end

    unless opts.is_a?(Hash)
      raise ArgumentError, 'JsonExporter opts is not a hash'
    end

    opts[:version]       ||= opts.delete(:v) || 1
    opts[:depth]         ||= 2 # 2 is default depth
    opts[:current_depth] ||= 0
    opts[:current_depth] += 1

    unallowed = opts.keys - %i(user version depth current_depth exporter)
    raise ArgumentError, 'Unallowed key JsonExporter option found: %s' % unallowed.first if unallowed.first

    @model    = model
    @version  = opts[:version]
    @user     = opts[:user]
    @opts     = opts
    @block    = _find_exporter

    @response = {}.to_hwia
  end

  def render
    instance_exec &@block
    instance_exec &EXPORTERS[:__filter]
    @response
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

  # copy calls from lesser version of the same exporter
  def copy version=nil
    version ||= @opts[:version] - 1
    exporter = _find_exporter version
    instance_exec &exporter
  end

  # finds versioned exporter
  def _find_exporter version=nil
    version  ||= @version
    exporter   = @opts.delete(:exporter) || model.class
    @exporter  = exporter.to_s.classify

    for num in version.downto(1).to_a
      if block = EXPORTERS.dig(num, @exporter)
        return block
      end
    end

    raise('Exporter "%s" (:%s) not found' % [exporter, exporter.to_s.underscore])
  end
end

