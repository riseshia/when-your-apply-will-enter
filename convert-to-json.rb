require 'json'
require 'csv'

module ConvertToJson
  module_function

  Stats = Struct.new(:month, :old_applied, :new_applied, :completed, :accepted, :declined, :other, keyword_init: true) do
    def to_h
      {
        month:,
        old_applied:,
        new_applied:,
        completed:,
        accepted:,
        declined:,
        other:,
      }
    end
  end

  CATEGORY_TO_FIELD = {
    '受理_旧受' => :old_applied,
    '受理_新受' => :new_applied,
    '既済_総数' => :completed,
    '既済_許可' => :accepted,
    '既済_不許可' => :declined,
    '既済_その他' => :other,
  }.freeze

  # e-Stat の CSV は先頭にメタデータ行が並ぶので、`tab_code` を含むヘッダ行以降だけを残す
  def extract_table(raw)
    raw.split("\n").drop_while { |line| !line.include?('tab_code') }.join("\n")
  end

  # 一桁の月にゼロ埋めして文字列ソートが暦順になるようにする (例: "2020年1月" -> "2020年01月")
  def normalize_month(month)
    return month unless month.size == 7

    y, m = month.split("年")
    "#{y}年0#{m}"
  end

  def build_stats(csv_text)
    stats_per_month = Hash.new { |h, k| h[k] = Stats.new(month: k) }

    CSV.parse(csv_text, headers: true).each do |row|
      month = normalize_month(row['時間軸（月次）'])
      field = CATEGORY_TO_FIELD[row['在留資格審査の受理・処理']]
      next unless field

      stats_per_month[month][field] = row['value'].to_i
    end

    stats_per_month.values.sort_by(&:month)
  end

  def convert(raw)
    stats = build_stats(extract_table(raw))
    JSON.pretty_generate(stats.map(&:to_h))
  end
end

if __FILE__ == $PROGRAM_NAME
  File.write('data.json', ConvertToJson.convert(File.read('data.csv')))
end
