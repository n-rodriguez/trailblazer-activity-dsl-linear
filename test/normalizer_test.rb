require "test_helper"

# Test the normalizer "activity".
# Here we simply run the normalizers and check if they generate the correct input hash (for the DSL).
class NormalizerTest < Minitest::Spec
  describe "Path" do
    let(:normalizer) do
      seq = Trailblazer::Activity::Path::DSL.normalizer

      process = compile_process(seq)
      circuit = process.to_h[:circuit]
    end

    it "normalizer" do
      signal, (ctx, _) = normalizer.([{user_options: {}}])

      ctx.inspect.must_equal %{{:connections=>{:success=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :success]}, :outputs=>{:success=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Right, semantic=:success>}, :user_options=>{}, :sequence_insert=>[#<Method: Trailblazer::Activity::DSL::Linear::Insert.Prepend>, \"End.success\"], :magnetic_to=>:success}}
    end
  end

  describe "Railway" do
    let(:normalizer) do
      seq = Trailblazer::Activity::Railway::DSL.normalizer

      process = compile_process(seq)
      circuit = process.to_h[:circuit]
    end

    let(:normalizer_for_fail) do
      seq = Trailblazer::Activity::Railway::DSL.normalizer_for_fail

      process = compile_process(seq)
      circuit = process.to_h[:circuit]
    end

    it "normalizer" do
      signal, (ctx, _) = normalizer.([{user_options: {}}])

      ctx.inspect.must_equal %{{:connections=>{:failure=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :failure], :success=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :success]}, :outputs=>{:failure=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Left, semantic=:failure>, :success=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Right, semantic=:success>}, :user_options=>{}, :sequence_insert=>[#<Method: Trailblazer::Activity::DSL::Linear::Insert.Prepend>, \"End.success\"], :magnetic_to=>:success}}
    end

    it "normalizer_for_fail" do
      signal, (ctx, _) = normalizer_for_fail.([{user_options: {}}])

      ctx.inspect.must_equal %{{:connections=>{:failure=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :failure], :success=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :failure]}, :outputs=>{:failure=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Left, semantic=:failure>, :success=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Right, semantic=:success>}, :user_options=>{}, :sequence_insert=>[#<Method: Trailblazer::Activity::DSL::Linear::Insert.Prepend>, \"End.success\"], :magnetic_to=>:failure}}
    end
  end

  describe "FastTrack" do
    let(:normalizer) do
      seq = Trailblazer::Activity::FastTrack::DSL.normalizer

      process = compile_process(seq)
      circuit = process.to_h[:circuit]
    end

    it " accepts :fast_track => true" do
      signal, (ctx, _) = normalizer.([{fast_track: true}])

      ctx.inspect.must_equal %{{:connections=>{:failure=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :failure], :success=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :success], :fail_fast=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :fail_fast], :pass_fast=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :pass_fast]}, :outputs=>{:pass_fast=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::FastTrack::PassFast, semantic=:pass_fast>, :fail_fast=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::FastTrack::FailFast, semantic=:fail_fast>, :failure=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Left, semantic=:failure>, :success=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Right, semantic=:success>}, :fast_track=>true, :sequence_insert=>[#<Method: Trailblazer::Activity::DSL::Linear::Insert.Prepend>, \"End.success\"], :magnetic_to=>:success}}
    end

    it " accepts :pass_fast => true" do
      signal, (ctx, _) = normalizer.([{pass_fast: true}])

      ctx.inspect.must_equal %{{:connections=>{:failure=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :failure], :success=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :pass_fast]}, :outputs=>{:failure=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Left, semantic=:failure>, :success=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Right, semantic=:success>}, :pass_fast=>true, :sequence_insert=>[#<Method: Trailblazer::Activity::DSL::Linear::Insert.Prepend>, \"End.success\"], :magnetic_to=>:success}}
    end

    it " accepts :fail_fast => true" do
      signal, (ctx, _) = normalizer.([{fail_fast: true}])

      ctx.inspect.must_equal %{{:connections=>{:failure=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :fail_fast], :success=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :success]}, :outputs=>{:failure=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Left, semantic=:failure>, :success=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Right, semantic=:success>}, :fail_fast=>true, :sequence_insert=>[#<Method: Trailblazer::Activity::DSL::Linear::Insert.Prepend>, \"End.success\"], :magnetic_to=>:success}}
    end

    it "goes without options" do
      signal, (ctx, _) = normalizer.([{}])

      ctx.inspect.must_equal %{{:connections=>{:failure=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :failure], :success=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :success]}, :outputs=>{:failure=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Left, semantic=:failure>, :success=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Right, semantic=:success>}, :sequence_insert=>[#<Method: Trailblazer::Activity::DSL::Linear::Insert.Prepend>, \"End.success\"], :magnetic_to=>:success}}
    end

    describe "normalizer_for_fail" do
      let(:normalizer_for_fail) do
        seq = Trailblazer::Activity::FastTrack::DSL.normalizer_for_fail

        process = compile_process(seq)
        circuit = process.to_h[:circuit]
      end

      it " accepts :fast_track => true" do
        signal, (ctx, _) = normalizer_for_fail.([{fast_track: true}])

        ctx.inspect.must_equal %{{:connections=>{:failure=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :failure], :success=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :failure], :fail_fast=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :fail_fast], :pass_fast=>[#<Method: Trailblazer::Activity::DSL::Linear::Search.Forward>, :pass_fast]}, :outputs=>{:pass_fast=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::FastTrack::PassFast, semantic=:pass_fast>, :fail_fast=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::FastTrack::FailFast, semantic=:fail_fast>, :failure=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Left, semantic=:failure>, :success=>#<struct Trailblazer::Activity::Output signal=Trailblazer::Activity::Right, semantic=:success>}, :fast_track=>true, :sequence_insert=>[#<Method: Trailblazer::Activity::DSL::Linear::Insert.Prepend>, \"End.success\"], :magnetic_to=>:failure}}
      end
    end
  end

  describe "Activity-style normalizer" do
    let(:implementing) do
      implementing = Module.new do
        extend T.def_tasks(:a, :b, :c, :d, :f, :g)
      end
    end

    it "what" do


      def my_step_interface_builder(callable_with_step_interface)
        ->((ctx, flow_options), *) do
          ctx = callable_with_step_interface.(ctx, **ctx)
          return Trailblazer::Activity::Right, [ctx, flow_options]
        end
      end



      macro_hash = {task: implementing.method(:b)}

      normalizer.(options: implementing.method(:a), user_options: {step_interface_builder: method(:my_step_interface_builder)}).must_equal({})  # step WrapMe, output: 1
      normalizer.(options: macro_hash, user_options: {})               # step task: Me, output: 1 (not using macro)
      normalizer.(options: macro_hash, user_options: {output: 1})         # step {task: Me}, output: 1   macro, user_opts
    end

    let(:normalizer) do
      seq = Trailblazer::Activity::FastTrack::DSL.normalizer
      seq = Linear::Normalizer.activity_normalizer(seq)

      process = compile_process(seq)
      normalizer = process.to_h[:circuit]
    end

    it "macro hash can set user_options such as {fast_track: true}" do
      signal, (cfg, _) = normalizer.(options: {fast_track: true}, user_options: {bla: 1})

      cfg.keys.must_equal [:connections, :outputs, :fast_track, :bla, :sequence_insert, :magnetic_to]
      cfg[:connections].keys.must_equal [:failure, :success, :fail_fast, :pass_fast]
    end

    it "user_options can override options" do
      signal, (cfg, _) = normalizer.(options: {fast_track: true}, user_options: {bla: 1, fast_track: false})

      cfg.keys.must_equal [:connections, :outputs, :fast_track, :bla, :sequence_insert, :magnetic_to]
      cfg[:connections].keys.must_equal [:failure, :success] # fast_track: false overrides the macro.
    end
  end
end