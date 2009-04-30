module Shoulda
  class StaticContext < Context  # :nodoc:
    MAGIC_TEST_CASE_INSTANCE_VARIABLES = %w{@method_name @loaded_fixtures @fixture_cache @_result @test_passed}
    undef_method :teardown

    attr_accessor :post_setup_instance_variables

    def setup_already_run?
      !post_setup_instance_variables.nil?
    end

    def run_all_setup_blocks(binding)
      if setup_already_run?
        post_setup_instance_variables.each do |name, value|
          binding.send(:instance_variable_set, name, value)
        end
      else
        run_parent_setup_blocks(binding)
        run_current_setup_blocks(binding)
        self.post_setup_instance_variables = {}
        binding.send(:instance_variables).each do |name|
          next if MAGIC_TEST_CASE_INSTANCE_VARIABLES.include? name
          post_setup_instance_variables[name] = binding.send(:instance_variable_get, name)
        end
      end
    end

    def should(name, options = {})
      raise ArgumentError, "Before should's are not valid in a StaticContext." if options[:before]
      super
    end

    def create_test_from_should_hash(should)
      test_name = ["test:", full_name, "should", "#{should[:name]}. "].flatten.join(' ').to_sym

      if test_unit_class.instance_methods.include?(test_name.to_s)
        warn "  * WARNING: '#{test_name}' is already defined"
      end

      context = self
      test_unit_class.send(:define_method, test_name) do
        context.run_all_setup_blocks(self)
        should[:block].bind(self).call
      end
    end
  end
end
