require "test_helper"

class InjectAlwaysOptionTest < Minitest::Spec
#@ we actually don't need {always: true}
#@ Inject() is always called.
  it "Inject(:name, always: true)" do
    class Create < Trailblazer::Activity::Railway
      step :write,
        Inject(:name) => ->(ctx, **) { ctx[:field] },
      #@ no {always: true}
        Inject() => [:date, :time],
        # TODO: deprecate this in favor of {Inject(:name)}.
        Inject() => {
          year: ->(ctx, date:, **) { "<Year of #{date}>" },
          never: ->(ctx, never:, call:, **) { raise "i shouldn't be called!" },
        }

      def write(ctx, time: "Time.now", date:, current_user:, name:, **) # {date} has no default configured.
        ctx[:log] = %{
ctx keys:     #{ctx.keys.inspect}
time:         #{time.inspect}
ctx[:time]:   #{ctx[:time].inspect}
date:         #{date}
current_user: #{current_user}
ctx[:model]:  #{ctx[:model]}
ctx[:year]:   #{ctx[:year].inspect}

name:         #{name.inspect}
}
      end
    end

    assert_invoke Create, never: true, time: "yesterday", date: "today", model: Object, current_user: Module, field: :mode, expected_ctx_variables: {
      log: %{
ctx keys:     [:seq, :never, :time, :date, :model, :current_user, :field, :name, :year]
time:         "yesterday"
ctx[:time]:   "yesterday"
date:         today
current_user: Module
ctx[:model]:  Object
ctx[:year]:   "<Year of today>"

name:         :mode
}
    }
  end
end

class InjectTest < Minitest::Spec
  it "Inject(circuit_interface: true)" do
    module XX
      class Create < Trailblazer::Activity::Railway
        #@ Inject with :instance_method
        #@        with [:array]
        step :write,
          Inject(:current_user) => :my_instance_method_for_current_user, # TODO: document.
          Inject() => [:date, :time],
          Inject() => {
            year: ->(ctx, date:, **) { "<Year of #{date}>" },
            never: ->(ctx, never:, call:, **) { raise "i shouldn't be called!" },
          },
          In() => [:model],
          # In() => [:date],
          In() => {:something => :thing}

        def write(ctx, time: "Time.now", date:, current_user:, **) # {date} has no default configured.
          ctx[:log] = %{
ctx keys:     #{ctx.keys.inspect}
time:         #{time.inspect}
ctx[:time]:   #{ctx[:time].inspect}
date:         #{date}
current_user: #{current_user}
ctx[:model]:  #{ctx[:model]}
ctx[:thing]:  #{ctx[:thing].inspect}
ctx[:year]:   #{ctx[:year].inspect}
}
        end

        def my_instance_method_for_current_user(ctx, model:, **)
          "<Currentuser for #{model}>"
        end
      end
    end # XX

  #@ {:something} is mapped via In
    assert_invoke XX::Create, never: true, time: "yesterday", date: "today", model: Object, something: 99, expected_ctx_variables: {
      log: %{
ctx keys:     [:model, :thing, :current_user, :date, :time, :year, :never]
time:         "yesterday"
ctx[:time]:   "yesterday"
date:         today
current_user: <Currentuser for Object>
ctx[:model]:  Object
ctx[:thing]:  99
ctx[:year]:   "<Year of today>"
}
    }

  #@ {:time} is defaulted in {#write}
    assert_invoke XX::Create, never: true, date: "today", model: Object, something: 99, expected_ctx_variables: {
      log: %{
ctx keys:     [:model, :thing, :current_user, :date, :year, :never]
time:         "Time.now"
ctx[:time]:   nil
date:         today
current_user: <Currentuser for Object>
ctx[:model]:  Object
ctx[:thing]:  99
ctx[:year]:   "<Year of today>"
}
    }

  #@ {:time} is defaulted in {#write}
  #@ {:year} is passed-through
    assert_invoke XX::Create, never: true, date: "today", model: Object, something: 99, year: "2022", expected_ctx_variables: {
      log: %{
ctx keys:     [:model, :thing, :current_user, :date, :year, :never]
time:         "Time.now"
ctx[:time]:   nil
date:         today
current_user: <Currentuser for Object>
ctx[:model]:  Object
ctx[:thing]:  99
ctx[:year]:   "2022"
}
    }

#@ {:current_user} passed from outside, defaulting not called
    assert_invoke XX::Create, never: true, date: "today", model: Object, current_user: Module, expected_ctx_variables: {
      log: %{
ctx keys:     [:model, :thing, :current_user, :date, :year, :never]
time:         "Time.now"
ctx[:time]:   nil
date:         today
current_user: Module
ctx[:model]:  Object
ctx[:thing]:  nil
ctx[:year]:   "<Year of today>"
}
    }

  end
end


class VariableMappingUnitTest < Minitest::Spec

  describe "SetVariable" do
    it "SetVariable#call can invoke a {Circuit.Step}" do
      my_exec_context = Class.new do
        def my_model(ctx, current_user:, **)
          "<MyModel #{current_user}>"
        end
      end.new

      user_filter = :my_model

      filter = Trailblazer::Activity::Circuit.Step(user_filter, option: true)

      pipe_task = Trailblazer::Activity::DSL::Linear::VariableMapping::SetVariable.new(variable_name: :model, filter: filter, user_filter: user_filter, name: :model)


      ctx = {current_user: Object, mode: :update}


      wrap_ctx = {aggregate: {}}


      wrap_ctx, _ = pipe_task.(wrap_ctx, [[ctx, {}], {exec_context: my_exec_context}])

      assert_equal wrap_ctx[:aggregate], {:model=>"<MyModel Object>"}
    end

    it "SetVariable#call can invoke any self-made circuit-step interface filter" do
      my_lowlevel_inject_filter = ->((ctx, flow_options), **) { "<MyModel #{ctx.fetch(:current_user)}>" }

      pipe_task = Trailblazer::Activity::DSL::Linear::VariableMapping::SetVariable.new(variable_name: :model, filter: my_lowlevel_inject_filter, user_filter: my_lowlevel_inject_filter, name: :model)


      ctx = {current_user: Object, mode: :update}


      wrap_ctx = {aggregate: {}}


      wrap_ctx, _ = pipe_task.(wrap_ctx, [[ctx, {}], {}])

      assert_equal wrap_ctx[:aggregate], {:model=>"<MyModel Object>"}
      end


  end

  #@ unit test
  it "In filters" do
    activity = Class.new(Trailblazer::Activity::Railway) do
      step task: Object,

        In() => [:params], # 1
        In() => [:mode, :styles], # 2,3
        In() => {:current_user => :user}, # 4

        Out() => [:result], # 1
        Out() => [:message, :status], # 2,3
        Out() => {:code => :error_code}, # 4

        Inject(:field) => ->(*) { :date } # 5
    end

    input_pipe = activity.to_h[:config][:wrap_static][Object].to_a[0][1].instance_variable_get(:@pipe).to_a

    set_variable = input_pipe[1][1]
    assert_equal set_variable.instance_variable_get(:@variable_name), :params
    assert_equal set_variable.instance_variable_get(:@name), :params

    set_variable = input_pipe[2][1]
    assert_equal set_variable.instance_variable_get(:@variable_name), :mode
    assert_equal set_variable.instance_variable_get(:@name), :mode

    set_variable = input_pipe[3][1]
    assert_equal set_variable.instance_variable_get(:@variable_name), :styles
    assert_equal set_variable.instance_variable_get(:@name), :styles

# {:variable_name} is what we write to ctx
    set_variable = input_pipe[4][1]
    #@ test the VariableFromCtx
    assert_equal set_variable.instance_variable_get(:@filter).instance_variable_get(:@variable_name), :current_user
    assert_equal set_variable.instance_variable_get(:@variable_name), :user
    assert_equal set_variable.instance_variable_get(:@name), :current_user

# Inject
    set_variable = input_pipe[5][1]
    #@ test the VariableFromCtx
    assert_equal set_variable.instance_variable_get(:@filter).instance_variable_get(:@variable_name), :field
    assert_equal set_variable.instance_variable_get(:@variable_name), :field
    assert_equal set_variable.instance_variable_get(:@name), :field

# Out
    output_pipe = activity.to_h[:config][:wrap_static][Object].to_a[2][1].instance_variable_get(:@pipe).to_a

    set_variable = output_pipe[1][1]
    assert_equal set_variable.instance_variable_get(:@variable_name), :result
    assert_equal set_variable.instance_variable_get(:@name), :result

    set_variable = output_pipe[2][1]
    assert_equal set_variable.instance_variable_get(:@variable_name), :message
    assert_equal set_variable.instance_variable_get(:@name), :message

    set_variable = output_pipe[3][1]
    assert_equal set_variable.instance_variable_get(:@variable_name), :status
    assert_equal set_variable.instance_variable_get(:@name), :status

    set_variable = output_pipe[4][1]
    assert_equal set_variable.instance_variable_get(:@variable_name), :error_code
    assert_equal set_variable.instance_variable_get(:@name), :code
  end
end
