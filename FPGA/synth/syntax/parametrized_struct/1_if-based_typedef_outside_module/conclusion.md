# 結論

参考にした Web 情報：[型のパラメータ化と interface based typedef](https://qiita.com/taichi-ishitani/items/ceee94d612c10bd08376)

Vivado Simulator 2024.1.2 で動作した。
struct 定義専用の interface を定義し、その捨てインスタンスを作って、本命の型を得る。
この方法なら論理合成も可能だろう。
