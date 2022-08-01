require "test_helper"

class ComposableVariableMappingDocTest < Minitest::Spec
  class ApplicationPolicy
    def self.can?(model, user, mode)
      decision = !user.nil?
      Struct.new(:allowed?).new(decision)
    end
  end

  module Steps
    def create_model(ctx, **)
      ctx[:model] = Object
    end
  end

  module A
    #:policy
    module Policy
      # Explicit policy, not ideal as it results in a lot of code.
      class Create
        def self.call(ctx, model:, user:, **)
          decision = ApplicationPolicy.can?(model, user, :create) # FIXME: how does pundit/cancan do this exactly?
          #~decision

          if decision.allowed?
            return true
          else
            ctx[:status]  = 422 # we're not interested in this field.
            ctx[:message] = "Command {create} not allowed!"
            return false
          end
          #~decision end
        end
      end
    end
    #:policy end
  end

#@ 0.1 No In()
  module AA
    Policy = A::Policy

    #:no-in
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create # an imaginary policy step.
      #~meths
      include Steps
      #~meths end
    end
    #:no-in end
  end

  it "why do we need In() ? because we get an exception" do
    exception = assert_raises ArgumentError do
      #:no-in-invoke
      result = Trailblazer::Activity::TaskWrap.invoke(AA::Create, [{current_user: Module}])

      #=> ArgumentError: missing keyword: :user
      #:no-in-invoke end
    end

    assert_equal exception.message, "missing keyword: :user"
  end

#@ In() 1.1 {:model => :model}
  module A
    #:in-mapping
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
        In() => {
          :current_user => :user, # rename {:current_user} to {:user}
          :model        => :model # add {:model} to the inner ctx.
        }
      #~meths
      include Steps
      #~meths end
    end
    #:in-mapping end

  end # A

  it "why do we need In() ?" do
    assert_invoke A::Create, current_user: Module, expected_ctx_variables: {model: Object}
  end

  module AAA
    #:in-mapping-keys
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step :show_ctx,
        In() => {
          :current_user => :user, # rename {:current_user} to {:user}
          :model        => :model # add {:model} to the inner ctx.
        }

      def show_ctx(ctx, **)
        p ctx.to_h
        #=> {:user=>#<User email:...>, :model=>#<Song name=nil>}
      end
      #~meths
      include Steps
      #~meths end
    end
    #:in-mapping-keys end

  end # A

  it "In() is only locally visible" do
    assert_invoke AAA::Create, current_user: Module, expected_ctx_variables: {model: Object}
  end

# In() 1.2
  module B
    Policy = A::Policy

    #:in-limit
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
        In() => {:current_user => :user},
        In() => [:model]
      #~meths
      include Steps
      #~meths end
    end
    #:in-limit end
  end

  it "In() can map and limit" do
    assert_invoke B::Create, current_user: Module, expected_ctx_variables: {model: Object}
  end

  it "Policy breach will add {ctx[:message]} and {:status}" do
    assert_invoke B::Create, current_user: nil, terminus: :failure, expected_ctx_variables: {model: Object, status: 422, message: "Command {create} not allowed!"}
  end

# In() 1.3 (callable)
  module BB
    Policy = A::Policy

    #:in-callable
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
        In() => ->(ctx, **) do
          # only rename {:current_user} if it's there.
          ctx[:current_user].nil? ? {} : {user: ctx[:current_user]}
        end,
        In() => [:model]
      #~meths
      include Steps
      #~meths end
    end
    #:in-callable end
  end

  it "In() can map and limit" do
    assert_invoke BB::Create, current_user: Module, expected_ctx_variables: {model: Object}
  end

  it "exception because we don't pass {:current_user}" do
    exception = assert_raises ArgumentError do
      result = Trailblazer::Activity::TaskWrap.invoke(BB::Create, [{}, {}]) # no {:current_user}
    end

    assert_equal exception.message, "missing keyword: :user"
  end

# In() 1.4 (filter method)
  module BBB
    Policy = A::Policy

    #:in-method
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
        In() => :input_for_policy, # You can use an {:instance_method}!
        In() => [:model]

      def input_for_policy(ctx, **)
        # only rename {:current_user} if it's there.
        ctx[:current_user].nil? ? {} : {user: ctx[:current_user]}
      end
      #~meths
      include Steps
      #~meths end
    end
    #:in-method end
  end

  it{ assert_invoke BBB::Create, current_user: Module, expected_ctx_variables: {model: Object} }

# In() 1.5 (callable with kwargs)
  module BBBB
    Policy = A::Policy

    #:in-kwargs
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
                      # vvvvvvvvvvvv keyword arguments rock!
        In() => ->(ctx, current_user: nil, **) do
          current_user.nil? ? {} : {user: current_user}
        end,
        In() => [:model]
      #~meths
      include Steps
      #~meths end
    end
    #:in-kwargs end
  end

  it{ assert_invoke BBBB::Create, current_user: Module, expected_ctx_variables: {model: Object} }

# Out() 1.1
  module D
    Policy = A::Policy

    #:out-array
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
        In() => {:current_user => :user},
        In() => [:model],
        Out() => [:message]
      #~meths
      include Steps
      #~meths end
    end
    #:out-array end
  end

  it "Out() can limit" do
    #= policy didn't set any message
    assert_invoke D::Create, current_user: Module, expected_ctx_variables: {model: Object, message: nil}
    #= policy breach, {message_from_policy} set.
    assert_invoke D::Create, current_user: nil, terminus: :failure, expected_ctx_variables: {model: Object, message: "Command {create} not allowed!"}
  end

# Out() 1.2
  module C
    Policy = A::Policy

    #:out-hash
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
        In() => {:current_user => :user},
        In() => [:model],
        Out() => {:message => :message_from_policy}
      #~meths
      include Steps
      #~meths end
    end
    #:out-hash end
  end

  it "Out() can map" do
    #= policy didn't set any message
    assert_invoke C::Create, current_user: Module, expected_ctx_variables: {model: Object, message_from_policy: nil}
    #= policy breach, {message_from_policy} set.
    assert_invoke C::Create, current_user: nil, terminus: :failure, expected_ctx_variables: {model: Object, message_from_policy: "Command {create} not allowed!"}
  end


# Out() 1.3
  module DD
    Policy = A::Policy

    # Message = Struct.new(:data)
    #:out-callable
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
        In() => {:current_user => :user},
        In() => [:model],
        Out() => ->(ctx, **) do
          return {} unless ctx[:message]

          { # you always have to return a hash from a callable!
            :message_from_policy => ctx[:message]
          }
        end
      #~meths
      include Steps
      #~meths end
    end
    #:out-callable end
  end

  it "Out() can map with callable" do
    #= policy didn't set any message
    assert_invoke DD::Create, current_user: Module, expected_ctx_variables: {model: Object}
    #= policy breach, {message_from_policy} set.
    assert_invoke DD::Create, current_user: nil, terminus: :failure, expected_ctx_variables: {model: Object, message_from_policy: "Command {create} not allowed!"}
  end

# Out() 1.4
  module DDD
    Policy = A::Policy

    #:out-kw
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
        In() => {:current_user => :user},
        In() => [:model],
        Out() => ->(ctx, message: nil, **) do
          return {} if message.nil?

          { # you always have to return a hash from a callable!
            :message_from_policy => message
          }
        end
      #~meths
      include Steps
      #~meths end
    end
    #:out-kw end
  end

  it "Out() can map with callable" do
    #= policy didn't set any message
    assert_invoke DDD::Create, current_user: Module, expected_ctx_variables: {model: Object}
    #= policy breach, {message_from_policy} set.
    assert_invoke DDD::Create, current_user: nil, terminus: :failure, expected_ctx_variables: {model: Object, message_from_policy: "Command {create} not allowed!"}
  end

# Out() 1.5
  module DDDD
    Policy = A::Policy

    #:out-outer
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create,
        In() => {:current_user => :user},
        In() => [:model],
        Out() => [:message],

        Out(with_outer_ctx: true) => ->(inner_ctx, outer_ctx, **) do
          {
            errors: outer_ctx[:errors].merge(policy_message: inner_ctx[:message])
          }
        end
      #~meths
      include Steps
      #~meths end
    end
    #:out-outer end
  end

  it "Out() with {outer_ctx}" do
    #= policy didn't set any message
    assert_invoke DDDD::Create, current_user: Module, errors: {}, expected_ctx_variables: {:errors=>{:policy_message=>nil}, model: Object, message: nil}
    #= policy breach, {message_from_policy} set.
    assert_invoke DDDD::Create, current_user: nil, errors: {}, terminus: :failure, expected_ctx_variables: {model: Object, :errors=>{:policy_message=>"Command {create} not allowed!"}, :model=>Object, :message=>"Command {create} not allowed!"}
  end

# Macro 1.0
  module DDDDD
    Policy = A::Policy
    #:macro
    module Policy
      def self.Create()
        {
          task: Policy::Create,
          wrap_task: true,
          Trailblazer::Activity::Railway.In()  => {:current_user => :user},
          Trailblazer::Activity::Railway.In()  => [:model],
          Trailblazer::Activity::Railway.Out() => {:message => :message_from_policy},
        }
      end
    end
    #:macro end

    #:macro-use
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create()
      #~meths
      include Steps
      #~meths end
    end
    #:macro-use end
  end

  it "Out() with {outer_ctx}" do
    #= policy didn't set any message
    assert_invoke DDDDD::Create, current_user: Module, expected_ctx_variables: {model: Object, message_from_policy: nil}
    #= policy breach, {message_from_policy} set.
    assert_invoke DDDDD::Create, current_user: nil, terminus: :failure, expected_ctx_variables: {model: Object, :message_from_policy=>"Command {create} not allowed!"}
  end

# Macro 1.1
  module DDDDDD
    Policy = DDDDD::Policy

    #:macro-merge
    class Create < Trailblazer::Activity::Railway
      step :create_model
      step Policy::Create(),
        Out() => {:message => :copied_message}
      #~meths
      include Steps
      #~meths end
    end
    #:macro-merge end
  end

  it "Out() with {outer_ctx}" do
    #= policy didn't set any message
    assert_invoke DDDDDD::Create, current_user: Module, expected_ctx_variables: {model: Object, message_from_policy: nil, :copied_message=>nil}
    #= policy breach, {message_from_policy} set.
    assert_invoke DDDDDD::Create, current_user: nil, terminus: :failure, expected_ctx_variables: {model: Object, :message_from_policy=>"Command {create} not allowed!", :copied_message=>"Command {create} not allowed!"}
  end

  # def operation_for(&block)
  #   namespace = Module.new
  #   # namespace::Policy = A::Policy
  #   namespace.const_set :Policy, A::Policy

  #   namespace.module_eval do
  #     operation = yield
  #     operation.class_eval do
  #       include Steps
  #     end
  #   end
  # end # operation_for
end