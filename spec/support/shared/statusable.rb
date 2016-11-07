require 'activemodel_translation/helper'
require 'support/active_record'

RSpec.shared_context 'statusable' do
  let(:instance) { model.new }

  def assert_filter(expected, &block)
    expected = relation_values(model.instance_exec(&expected))
    expect(relation_values(model.instance_exec(&block))).to eq expected
  end

  if RailsStuff.rails4?
    def relation_values(relation)
      where_sql = relation.where_values.map(&:to_sql).join
      values_sql = relation.bind_values.map(&:second).join
      [where_sql, values_sql]
    end
  else
    def relation_values(relation)
      where_sql = relation.where_clause.ast.to_sql
      values_sql = relation.where_clause.binds.map(&:value).join
      [where_sql, values_sql]
    end
  end

  def add_translations(data)
    I18n.backend = I18n::Backend::Simple.new
    data.each do |field, values|
      I18n.backend.store_translations 'en', strings: {
        "#{field}_name" => values.map { |x| [x, "#{x}_en"] }.to_h,
      }
    end
  end
end
