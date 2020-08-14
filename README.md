# FM-7 64180CPUカード用CP/M BIOS

本プログラムはFM-7シリーズ用のCPU64180カード上で動作する63k CP/M用のBIOSです。

## 対応ハードウェア

**64180CPUカード8MHz版(プロセッサ1988年8月)を下記の通り変更したもの。**
* RAMを512KSRAM(AS6C4008)に変更
* RAMの開始アドレスを80000Hに変更

## 利用環境

　FM-7、FM-77

## 主な特徴

* CP/M起動後はFM-7のメインCPUは動作せず、I/Oはすべて64180で実行。
* EMX80を参考に、サブシステムとのやり取りはタイマー割込み内で実行。
* ブロッキング・デブロッキング処理有。

## 参考にしたもの
* 63K CP/Mの制作(Oh!FM 1986年7月)<br>
IPL、BIOS09をそのまま使用しています。<br>
※添付ソースは逆アセンブルして整形・コメント追加したものです。

* 64180CPUカードの設計・製作(プロセッサ 1988年1月及び8月)

* EMX80(I/O 1985年4月)<br>
サブCPUとのインターフェース

* [CP／Mコーナー](http://star.gmobb.jp/koji/cgi/wiki.cgi?page=CP%A1%BFM%A5%B3%A1%BC%A5%CA%A1%BC)
 
* [The Unofficial CP/M Web site](http://www.cpm.z80.de/index.html)

* [Retro PC Gallery](http://haserin09.la.coocan.jp/index.html)


## アセンブル
* Z80(64180)ソースのアセンブルはHI-TECH Z80 CP/M C compilerに付属のZASとLINKを使用してください。
* 6809ソースのアセンブルはASM6809を使用してください。<br>
http://www.6809.org.uk/asm6809/<br>
asm6809 -9 -B -o XXXXX.bin XXXXX.asm

## モジュールの書き込み位置
* IPL：track=0,sector=1,side=0
* CCP+BDOS+BIOS+BIOS09：track=0,sector=2,side=0
* BIOS2：track=0,sector=1,side=1

