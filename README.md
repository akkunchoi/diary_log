## これは何？

テキストで記述された日記ファイルを解析して集計します。
Google Calendarにイベントとして作成することもできます。


## 使用例

1. config.sample.ymlを参考にconfig.ymlを記述します

2. 実行します。

    $ ruby main.rb


## フォーマットについて

1日の出来事を1ファイルで記述します。ファイル名は「YYYY-mm-dd」を含むようにします。
先頭行には必ず YYYY-mm-dd の日付を記述します。
その他の行はその日にあった出来事の「レコード」になります。

レコードは行単位で、 "HH:MM 出来事" のフォーマットで記述します。
分（:MM）は省略可能です。全日に渡るイベント、その日の全体的な感想は "HH:MM" の代わりに "*" とします。

出来事は、その時間に「発生したイベント」や「終了したイベント」を記録します。
出来事は新しいものから順に記述しなければなりません。

日記の例です。

    2013-01-27

    * 今日は有意義な日だった。

    1:00 寝た
    19 夕飯
    18 project2 モジュール××を書いた
    12:30 昼食
    12 project1 A氏と打合せ
    10 事務所
    9:30 朝食、準備
    8:30 起きた

この例は 1月27日に「8:30に起床、9:30に朝食が終わる。10〜12時はproject1についての打合せ。12時〜12時半まで昼食。
12時半〜18時までproject2。18時〜19時まで夕飯。1時（25時）に就寝。」ということを意味します。
