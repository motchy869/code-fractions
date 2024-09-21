# 結論

参考にした Web 情報：[型のパラメータ化と interface based typedef](https://qiita.com/taichi-ishitani/items/ceee94d612c10bd08376)

テストベンチで virtual interface を使えない。
なぜなら interface の入れ子が必要になるから。
Vivado simulator 2024.1.2 では elaboration で segmentation fault が発生する。
