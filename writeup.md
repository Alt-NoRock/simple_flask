# AWS App Runner で Flask アプリを動かすまで

Herokuの無料プランが終了し、11月までの移行が必要  
代替サービスへの移行も考えたいけど、会社でAWS使っているし練習には丁度いいか〜という意味合いで調べてやってみたという話です。  
Web初心者なので、不明確な内容にはマサカリ投げてください

# そもそもAWS APP Runner って？
ビルド時にポートスキャンしてみたりとか、一応動きは確認してくれている感がある。  


# 動かしてみた
## Simple な Python

## pipenv を利用する場合
こちらもそこまで変更ありません  
pipenv のインストールコマンドを APP runner側の設定として入れ込めば問題ありません。  

```bash
pipenv install flask gunicorn
```

* 構築コマンド: pip install pipenv && pipenv install --python 3.8
* 起動コマンド: pipenv run python -m gunicorn app:app
* ポート : 5000

とすればOKでした。  
pipenv で --python バージョンで インストールするpythonのバージョンを指定します。  
当初はオプション指定していなかったのですが、

* Pipfileで version指定をしているにもかかわらず、pipenv install の際に python3.9 で環境が作成される？
  * requirements.txt と Pipfile を評価のために二重登録していたのですが、　途中で requirements.txt -> Pipfileへの変換処理が走っている様なログが存在しておりPipfileが更新されている？ 
* AWS のデフォルト使用コンテナは 335838599203.dkr.ecr.ap-northeast-1.amazonaws.com/awsfusionruntime-python3:3.8.5
  * pyenv がプリインストールされていないため、 python 3.8 出ない場合にビルドエラーとなる

といった理由から指定しています。  

### 余談 : requirements.txt と Pipfile 両方指定しているか確認してみた

要は、差分を作っておけばいいんでしょ？という気がしているので、以下のようなことをやってみました。  
```Pipfile
```

```requirements.txt
```

結果  


## 所管とか
ビルド時間がそこまで早くないため、素直にECRも使ってコンテナ型の起動をしたほうが間違いが少なくて良いのでは？と思っています。  
