require 'active_support/core_ext/object/blank'

RSpec.describe RailsStuff::TransformAttrs do
  let(:klass) do
    described_class = self.described_class
    Class.new do
      def self.extra_ancestors
        ancestors.take_while { |x| x != Object }.
          # rails 4 adds ActiveSupport::ToJsonWithActiveSupportEncoder.
          # We ignore it:
          reject(&:name)
      end

      extend described_class
      attr_accessor :own
    end
  end

  describe 'writers' do
    let(:instance) { klass.new }
    before do
      klass.send :include, Module.new { attr_accessor :nested }
      klass.transform_attrs :own, with: :strip
      klass.transform_attrs :nested, with: :nullify
    end

    it 'works for own attrs' do
      expect { instance.own = ' test' }.to change(instance, :own).to('test')
      expect { instance.own = '     ' }.to change(instance, :own).to('')
      expect { instance.own = [1] }.to change(instance, :own).to('[1]')
      expect { instance.own = [] }.to change(instance, :own).to('[]')
    end

    it 'works for nested attrs' do
      expect { instance.nested = ' test' }.to change(instance, :nested).to(' test')
      expect { instance.nested = '     ' }.to change(instance, :nested).to(nil)
      expect { instance.nested = [1] }.to change(instance, :nested).to([1])
      expect { instance.nested = [] }.to change(instance, :nested).to(nil)
    end

    context 'for chained translations' do
      before do
        klass.transform_attrs :own, with: %i[strip nullify]
        klass.transform_attrs :nested, with: %i[nullify strip]
      end

      it 'applies them all' do
        expect { instance.own = ' test' }.to change(instance, :own).to('test')
        expect { instance.own = '    ' }.to change(instance, :own).to(nil)
        expect { instance.own = [] }.to change(instance, :own).to('[]')

        expect { instance.nested = ' test' }.to change(instance, :nested).to('test')
        expect { instance.nested = '     ' }.to change(instance, :nested).to(nil)
        expect { instance.nested = [] }.to_not change(instance, :nested).from(nil)
      end
    end
  end

  describe '.transform_attrs' do
    subject { ->(*args, &block) { klass.transform_attrs(*args, &block) } }

    it 'adds only single module by default' do
      expect do
        subject.call :one, &:presence
        subject.call :two, &:presence
      end.to change(klass, :extra_ancestors).from([klass]).to([instance_of(Module), klass])
    end

    it 'includes new modules with `new_module:` option' do
      expect { subject.call :two, new_module: :include, &:presence }.
        to change(klass, :extra_ancestors).from([klass]).
        to([klass, instance_of(Module)])
      expect { subject.call :one, &:presence }.
        to change(klass, :extra_ancestors).
        to([instance_of(Module), klass, instance_of(Module)])
      expect { subject.call :two, new_module: :prepend, &:presence }.
        to change(klass, :extra_ancestors).
        to([instance_of(Module), instance_of(Module), klass, instance_of(Module)])
    end

    it 'raises error when invalid translation requested' do
      expect { subject.call :one, with: :missing }.to raise_error(KeyError)
      expect { subject.call :one, with: %i[nullify missing] }.to raise_error(KeyError)
    end
  end
end
