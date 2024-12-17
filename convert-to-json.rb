require 'json'
require 'csv'

rows = File.read('data.csv').split("\n")
rows = rows.drop_while { |row| !row.include?('tab_code') }

Stats = Struct.new(:month, :old_applied, :new_applied, :completed, :accepted, :declined, :other, keyword_init: true) do
  def to_h
    {
      month: month,
      old_applied: old_applied,
      new_applied: new_applied,
      completed: completed,
      accepted: accepted,
      declined: declined,
      other: other,
    }
  end
end

stats_per_month = Hash.new { |h, k| h[k] = Stats.new(month: k) }

rows = CSV.parse(rows.join("\n"), headers: true)
rows.each do |row|
  month = row['時間軸（月次）']
  if month.size == 7 # add leading zero for sort
    y, m = month.split("年")
    month = "#{y}年0#{m}"
  end

  stats = stats_per_month[month]
  category = row['在留資格審査の受理・処理']

  case category
  when '受理_旧受' then
    stats.old_applied = row['value'].to_i
  when '受理_新受' then
    stats.new_applied = row['value'].to_i
  when '既済_総数' then
    stats.completed = row['value'].to_i
  when '既済_許可' then
    stats.accepted = row['value'].to_i
  when '既済_不許可'
    stats.declined = row['value'].to_i
  when '既済_その他'
    stats.other = row['value'].to_i
  end
end

stats_list = stats_per_month.values.sort_by { |stats| stats.month }

result = JSON.pretty_generate(stats_list.map(&:to_h))
File.write('data.json', result)
