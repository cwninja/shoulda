module Shoulda
  class StaticContext < Context
    undef_method :setup
    undef_method :teardown

    attr_accessor :post_setup_instance_variables

    def static_setup(&blk)
      self.setup_blocks << blk
    end

    def create_test_from_should_hash(should)
      test_name = ["test:", full_name, "should", "#{should[:name]}. "].flatten.join(' ').to_sym

      if test_unit_class.instance_methods.include?(test_name.to_s)
        warn "  * WARNING: '#{test_name}' is already defined"
      end

      context = self
      self.post_setup_instance_variables = nil
      test_unit_class.send(:define_method, test_name) do
        begin
          if context.post_setup_instance_variables.nil?
            context.run_parent_setup_blocks(self)
            should[:before].bind(self).call if should[:before]
            context.run_current_setup_blocks(self)
            context.post_setup_instance_variables = {}
            self.instance_variables.each do |name|
              context.post_setup_instance_variables[name] = instance_variable_get(name)
            end
          else
            context.post_setup_instance_variables.each do |name, value|
              self.instance_variable_set(name, value)
            end
          end
          should[:block].bind(self).call
        end
      end
    end
  end
end
