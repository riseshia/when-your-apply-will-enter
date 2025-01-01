# when-your-apply-will-enter

入国管理国の永住権申請の様子を可視化しているページ、の実装です。

## 中身

- `index.html`: ページのHTML
- `main.js`: ページの JS。生成したデータをベースにグラフを出すロジックが書かれています
- `data.json`: ページに表示するデータです
- `convert-to-json.rb`: e-stat からダウンロードした `data.csv` からグラフに必要なデータにしてグラフを作りやすい `data.json` へ変換するスクリプトです
- `update-data.sh`: e-stat からデータをダウンロードして `data.csv` を更新するスクリプトです。 Actions で定期実行して更新 PR を作るようにしています

## 利用データ

[政府統計の総合窓口](https://www.e-stat.go.jp/) から「出入国管理統計 入国審査・在留資格審査・退去強制手続等」を利用しています。

## LICENSE

### 実装

MIT ライセンスです。

### データ

[政府統計の総合窓口（e-Stat）利用規約](https://www.e-stat.go.jp/terms-of-use) をご確認ください。
