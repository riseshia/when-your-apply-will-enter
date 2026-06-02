require 'minitest/autorun'
require_relative 'convert-to-json'

class ConvertToJsonTest < Minitest::Test
  def test_normalize_month_pads_single_digit_month
    assert_equal '2020年01月', ConvertToJson.normalize_month('2020年1月')
  end

  def test_normalize_month_keeps_double_digit_month
    assert_equal '2020年12月', ConvertToJson.normalize_month('2020年12月')
  end

  def test_extract_table_drops_metadata_rows_before_header
    raw = <<~CSV
      "STATISTICAL DATA SEARCH"
      "出入国管理統計"
      "tab_code","在留資格審査の受理・処理","時間軸（月次）","value"
      "00","受理_新受","2020年1月","100"
    CSV

    table = ConvertToJson.extract_table(raw)

    assert table.start_with?('"tab_code"')
    refute_includes table, 'STATISTICAL DATA SEARCH'
  end

  def test_build_stats_maps_categories_to_fields
    csv = <<~CSV
      "tab_code","在留資格審査の受理・処理","時間軸（月次）","value"
      "00","受理_旧受","2020年1月","1"
      "00","受理_新受","2020年1月","2"
      "00","既済_総数","2020年1月","3"
      "00","既済_許可","2020年1月","4"
      "00","既済_不許可","2020年1月","5"
      "00","既済_その他","2020年1月","6"
    CSV

    stats = ConvertToJson.build_stats(csv)

    assert_equal 1, stats.size
    assert_equal(
      {
        month: '2020年01月',
        old_applied: 1,
        new_applied: 2,
        completed: 3,
        accepted: 4,
        declined: 5,
        other: 6,
      },
      stats.first.to_h,
    )
  end

  def test_build_stats_sorts_months_chronologically
    csv = <<~CSV
      "tab_code","在留資格審査の受理・処理","時間軸（月次）","value"
      "00","受理_新受","2020年12月","12"
      "00","受理_新受","2020年2月","2"
      "00","受理_新受","2021年1月","13"
    CSV

    months = ConvertToJson.build_stats(csv).map(&:month)

    assert_equal ['2020年02月', '2020年12月', '2021年01月'], months
  end

  def test_build_stats_ignores_unknown_categories
    csv = <<~CSV
      "tab_code","在留資格審査の受理・処理","時間軸（月次）","value"
      "00","受理_新受","2020年1月","2"
      "00","未知のカテゴリ","2020年1月","999"
    CSV

    stats = ConvertToJson.build_stats(csv)

    assert_equal 1, stats.size
    assert_equal 2, stats.first.new_applied
    assert_nil stats.first.completed
  end

  # raw CSV から最終 JSON までを通しで検証する。
  # csv (パース) と json (生成 + 再パース) の両方を経由するので、
  # dependabot による csv / json の更新がこのテストに必ず当たる。
  def test_convert_round_trips_raw_csv_to_json
    raw = <<~CSV
      "STATISTICAL DATA SEARCH"
      "tab_code","在留資格審査の受理・処理","時間軸（月次）","value"
      "00","受理_新受","2020年12月","12"
      "00","既済_許可","2020年12月","10"
      "00","受理_新受","2020年2月","2"
    CSV

    parsed = JSON.parse(ConvertToJson.convert(raw))

    assert_equal ['2020年02月', '2020年12月'], parsed.map { |row| row['month'] }
    assert_equal 12, parsed.last['new_applied']
    assert_equal 10, parsed.last['accepted']
  end
end
