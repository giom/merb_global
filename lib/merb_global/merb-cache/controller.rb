# Monkey Patching merb-cache
module Merb::Cache::CacheMixin
  module ClassMethods
    # There is probably a much nicer way to do that than by playing around the blk like I'm doing now
    # I really don't like the duplication of merb-cache source code this method entails
    def global_eager_cache(trigger_action, target = trigger_action, conditions = {}, &blk)
      target, conditions = trigger_action, target if target.is_a? Hash

      if target.is_a? Array
        target_controller, target_action = *target
      else
        target_controller, target_action = self, target
      end

      Merb::Global::Locale.supported_locales.each do |loc|
        loc_blk = additionnal_param_block({:locale => loc}, blk)
        after("_eager_cache_#{loc}_#{trigger_action}_to_#{target_controller.name.snake_case}__#{target_action}_after", conditions.only(:if, :unless).merge(:with => [target_controller, target_action, conditions, loc_blk], :only => trigger_action))
        alias_method "_eager_cache_#{loc}_#{trigger_action}_to_#{target_controller.name.snake_case}__#{target_action}_after", :_eager_cache_after
      end
    end
    
    # Returns a proc used by Merb::Cache::CacheMixin eager_dispatch to instanciate the controller
    # This proc also sets the :locale param so that the action will be cached in the proper locale (by calling it with :locale => loc)
    def additionnal_param_block(hash, blk = nil)
      if blk
        Proc.new do |params, env|
          # Most of the following code comes from eager_dispatch
          blk_params = case blk.arity
            when 0  then  []
            when 1  then  [params]
            else          [*[params, env]]
          end
        
          res = blk[*blk_params]
          res = case res
            when NilClass         then new(Merb::Request.new(env))
            when Hash, Mash       then new(Merb::Request.new(res))
            when Merb::Request    then new(res)
            when Merb::Controller then res
            else raise ArgumentError, "Block to eager_cache must return nil, the env Hash, a Request object, or a Controller object"
          end
          res.params.merge!(hash)
          res
        end
      else
        Proc.new do |params, env|
          res = new(Merb::Request.new(env))
          res.params.merge!(hash)
          res
        end
      end
    end
  end
    
  def global_eager_cache(action, conditions = {}, params = request.params.dup, env = request.env.dup, &blk)
    unless @_skip_cache
      if action.is_a?(Array)
        klass, action = *action
      else
        klass = self.class
      end

      run_later do
        Merb::Global::Locale.supported_locales.each do |loc|
          loc_blk = additionnal_param_block({:locale => loc}, blk)
          controller = klass.eager_dispatch(action, params.dup, env.dup, loc_blk)
        end
      end
    end
  end
end