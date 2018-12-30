module Trailblazer
  class Activity < Module
    def self.Path(options={})
      Activity::Path.new(Path, options)
    end

    # Implementation module that can be passed to `Activity[]`.
    class Path < Activity
      # Default variables, called in {Activity::initialize}.
      def self.config
        {
          builder_class:    Magnetic::Builder::Path, # we use the Activity-based Normalizer
          normalizer_class: Magnetic::Normalizer,
          default_outputs:  Magnetic::Builder::Path.default_outputs, # binary outputs

          extend:           [
            # DSL.def_dsl(:task, Magnetic::Builder::Path,    :PassPolarizations),
            DSL::Linear.def_dsl(:_end, Magnetic::Builder::Path,    :EndEventPolarizations),
            DSL::Linear.def_dsl(:task, Magnetic::Builder::Railway, :PassPolarizations),
          ],
        }
      end

      module DSL
        Linear = Activity::DSL::Linear # FIXME

        module_function

        def normalizer
          step_options_for_path(Trailblazer::Activity::Path::DSL.initial_sequence)
        end

        # FIXME: where does Start come from?
        Right = Trailblazer::Activity::Right
        def start_sequence
          start_default = Trailblazer::Activity::Start.new(semantic: :default)
          start_event   = Linear::DSL.create_row(start_default, id: "Start.default", magnetic_to: nil, outputs: unary_outputs, connections: unary_connections)
          sequence      = Linear::Sequence[start_event]
        end

        # DISCUSS: still not sure this should sit here.
        # Pseudo-DSL that prepends {steps} to {sequence}.
        def prepend_to_path(sequence, steps)
          steps.each do |id, task|
            sequence = Linear::DSL.insert_task(task, sequence: sequence,
              magnetic_to: :success, id: id, outputs: unary_outputs, connections: unary_connections,
              sequence_insert: [Linear::Insert.method(:Prepend), "End.success"])
          end

          sequence
        end

        def unary_outputs
          {success: Activity::Output(Activity::Right, :success)}
        end

        def unary_connections
          {success: [Linear::Search.method(:Forward), :success]}
        end

        def merge_path_outputs((ctx, flow_options), *)
          ctx = {outputs: unary_outputs}.merge(ctx)

          return Right, [ctx, flow_options]
        end

        def merge_path_connections((ctx, flow_options), *)
          ctx = {connections: unary_connections}.merge(ctx)

          return Right, [ctx, flow_options]
        end

        def step_options_for_path(sequence)
          prepend_to_path(
            sequence,

            "path.outputs"     => method(:merge_path_outputs),
            "path.connections" => method(:merge_path_connections),
          )
        end



        # Returns an initial two-step sequence with {Start.default > End.success}.
        def initial_sequence
          # TODO: this could be an Activity itself but maybe a bit too much for now.
          sequence = start_sequence
          sequence = append_end(Activity::End.new(semantic: :success), sequence, magnetic_to: :success, id: "End.success")
        end

        def append_end(end_event, sequence, magnetic_to:, id:)
          end_args = {sequence_insert: [Linear::Insert.method(:Append), "Start.default"], stop_event: true}

          sequence = Linear::DSL.insert_task(end_event, sequence: sequence, magnetic_to: magnetic_to, id: id, outputs: {magnetic_to => end_event}, connections: {magnetic_to => [Linear::Search.method(:Noop)]}, **end_args)
        end
      end # DSL
    end # Path
  end
end

