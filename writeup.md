# AWS App Runner で Flask アプリを動かすまで

Herokuの無料プランが終了するらしく、個人で遊んでいたWebサーバを11月までにどこかに移管する必要がありました。    
代替サービスへの移行も考えたいけど、会社でAWS使うこともあるだろうし、練習には丁度いいか〜という意味合いで調べてやってみたという話です。  

# そもそも AWS APP Runner って？

ソースコードやコンテナから、Webサービスを構築できるフルマネージドサービスです。  
本来、Webサービスの構築には「Webサーバーの構築＋サーバー上で動作するアプリケーションの開発」が必要になります。  
が、本来実現したいのはWebサービスであり、Webサーバーの構築は省略したい内容です。  
その上、準備に過ぎないにもかかわらず多大な労力と深い専門性が必要になります。特に公開するアプリケーションの場合はスケーリングやセキュリティなどをケアしなくてはないません。  

その様な、ともすれば「面倒くさくて大変な」部分をAppRunnerが自動で構築することにより、Webサービス開発者はサービス用のアプリケーションに注力できる。  
というのが私の理解です。  
目指す未来は Heroku 等と近い気がしますね。  


# 動かしてみた
## 構築方式
2 * 2 = 4パターンの構築方式が有るようです。  

| 設定ファイル/ソースコード       | ソースコードを利用 | コンテナを利用 |
| :---:                           | :---:              | :---:         |
| AWSマネジメントコンソールで設定 | 1                  | 3              |
| 設定ファイルを利用              | 2                  | 4              |

お試しで実施するなら、ソースコードをGithubと連携しビルド＋デプロイするのが簡単です。  
今回は、ECRをトライしました。理由としては

* 毎回ソースコードでビルドしていると、サービスが本格的になるほど課金額が大きくなりそう
  * [公式サイトより](https://aws.amazon.com/jp/apprunner/pricing/)  0.005 USD/ビルド時間 (分)
* サービス依存性が少ない方式でトライしたい
  * AWSマネジメントコンソールでの設定がエクスポートしにくく、環境構築には設定ファイルを利用したい
  * ソースコード向けの設定ファイルはyml方式とはいえ、docker-compose等との互換性がなさそう
  * Dockerfile/docker-compose.yml ならば、自前サーバや他サービスへの移行が比較的しやすい
  
Heroku x ソースコードで試していて今回の移動騒ぎなので、サービス移行しやすいことは優先度が高かったです。

## Dockerの構成

試しているソースコードは[こちら]()に展開しておきました。  
各フェーズ毎にブランチを切っています。  

ポイントとしては、`Dockerfileで完結させている`という部分かと思います。  
普段dockerを利用している場合、 docker-compose.yml の設定項目で マウントポイントやポート開放 を設定していましたが、今回はECRにイメージをプッシュする必要があります。  
docker-compose.yml の上記設定は`docker-compose up`で利用されるため、イメージ内部に反映されず、Apprunner側での設定も出来ません。  
そのため、最初この部分でエラーになってしまいました（しかもエラー原因が解析困難、、、）  


## AWS CLIのインストールと初期設定
~~スクリーンショット貼るのが面倒なので~~作業上楽なので[AWS-CLI](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)をインストールします。  

```bash: aws-cli Install
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

```bash: 確認コマンド
$ usr/local/bin/aws --version
```
```log: 結果
aws-cli/2.7.33 Python/3.9.11 Linux/5.11.0-38-generic exe/x86_64.ubuntu.20 prompt/off
```

無事にインストール出来ました。  
初期設定もしていきます。（認証情報はIAMから確認していきます)  

```bash: aws cli への認証情報入力
aws configure
AWS Access Key ID [None]: ***********************************
AWS Secret Access Key [None]: ***********************************
Default region name [None]: ap-northeast-1
Default output format [None]: json
``` 

## IAMの設定  
最低限、以下が必要ですので設定していきます。  


* ecr:CreateRepository


## ECRの設定
ECRがない場合は以下の形で作成します。  

```bash: ECRの作成
aws ecr create-repository --repository-name sample_flask
```

登録方法はAWS-MangementConsoleにもコマンドがでますが、以下のとおりです。  
(docker build の部分を docker compose build で実施している部分のみが差分です。)  


```bash: ECRへのイメージプッシュ
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <AccountID>.dkr.ecr.ap-northeast-1.amazonaws.com
docker compose build
docker tag simple_flask_flask:latest <AccountID>.dkr.ecr.ap-northeast-1.amazonaws.com/sample_flask:latest
docker push <AccountID>.dkr.ecr.ap-northeast-1.amazonaws.com/sample_flask:latest
```


```bash: 確認コマンド
aws ecr list-images --repository-name sample_flask
```

```log: 結果
{
    "imageIds": [
        {
            "imageDigest": "sha256:06da045f53b6899f07be2c499213b9fb98712496d27d11a64427dbfa9e91d33f",
            "imageTag": "latest"
        }
    ]
}
```

無事に入ってますね！！


# APPrunnerの設定

設定自体を使いまわしたいので、 テンプレートファイルを使用します。  
aws コマンド全般ですが、 --generate-cli-skelton オプションで、必要情報のテンプレートJsonファイルを出力できます。  

```
aws apprunner create-service --generate-cli-skeleton

{
    "ServiceName": "",
    "SourceConfiguration": {
        "CodeRepository": {
            "RepositoryUrl": "",
            "SourceCodeVersion": {
                "Type": "BRANCH",
                "Value": ""
            },
            "CodeConfiguration": {
                "ConfigurationSource": "REPOSITORY",
                "CodeConfigurationValues": {
                    "Runtime": "PYTHON_3",
                    "BuildCommand": "",
                    "StartCommand": "",
                    "Port": "",
                    "RuntimeEnvironmentVariables": {
                        "KeyName": ""
                    }
                }
            }
        },
        "ImageRepository": {
            "ImageIdentifier": "",
            "ImageConfiguration": {
                "RuntimeEnvironmentVariables": {
                    "KeyName": ""
                },
                "StartCommand": "",
                "Port": ""
            },
            "ImageRepositoryType": "ECR"
        },
        "AutoDeploymentsEnabled": true,
        "AuthenticationConfiguration": {
            "ConnectionArn": "",
            "AccessRoleArn": ""
        }
    },
    "InstanceConfiguration": {
        "Cpu": "",
        "Memory": "",
        "InstanceRoleArn": ""
    },
    "Tags": [
        {
            "Key": "",
            "Value": ""
        }
    ],
    "EncryptionConfiguration": {
        "KmsKey": ""
    },
    "HealthCheckConfiguration": {
        "Protocol": "TCP",
        "Path": "",
        "Interval": 0,
        "Timeout": 0,
        "HealthyThreshold": 0,
        "UnhealthyThreshold": 0
    },
    "AutoScalingConfigurationArn": "",
    "NetworkConfiguration": {
        "EgressConfiguration": {
            "EgressType": "DEFAULT",
            "VpcConnectorArn": ""
        }
    },
    "ObservabilityConfiguration": {
        "ObservabilityEnabled": true,
        "ObservabilityConfigurationArn": ""
    }
}
```

~~すでにめんどくさい~~ 中身を確認していきます。  

|Request Parameters          | 型     | 必須  | 内容  |
|:---                        | :---:  | :---: | :--- |
|ServiceName                 | String | ○ | App Runner のサービス名 |
|SourceConfiguration         | Object | ○ | App Runner でデプロイするソースコード or イメージの設定情報     |
|InstanceConfiguration       | Object |    | App Runner インスタンスのスケールに関する設定情報               | 
|Tags                        | Array  |    | App Runner サービスのリソースに関連づけることのできるメタデータ |
|EncryptionConfiguration     | Object |    | App Runner で使用するソースコードやログの暗号化設定 |
|HealthCheckConfiguration    | Object |    | サービスのヘルスチェックを行うための設定 | 
|AutoScalingConfigurationArn | String |    | 自動スケーリングに関連する設定のARN情報 | 
|NetworkConfiguration        | Object |    | サービスのNWトラヒックに関連する設定 | 
|ObservabilityConfiguration  | Object |    | サービスのオブザーバビリティ構成 | 

必須要件は2件. SourceConfiguration は専用オブジェクトでの設定となりますので、深堀します。  

|SourceConfiguration Field   | 型      | 必須  | 内容  |
|:---                        | :---:   | :---: | :---  |
|AuthenticationConfiguration | Object  |       | ソースレポジトリへの認証情報 (AWS内部なら不要) |
|AutoDeploymentsEnabled      | Boolean |       | 自動デプロイの有無(ソースの変更をトリガーに自動でデプロイする) |
|CodeRepository              | Object  | どちらか必須/両選択NG | 使用するソースコードの設定 |
|ImageRepository             | Object  | どちらか必須/両選択NG | 使用するレポジトリの設定 |

|ImageRepository Field       | 型      | 必須  | 内容  |
|:---                        | :---:   | :---: | :---  |
|ImageIdentifier             | String  | ○    | イメージID.ECRの場合は docker pullで指定するURI (例: xxxxxxxx.dkr.ecr.ap-northeast-1.amazonaws.com/sample_flask:latest) |
|ImageConfiguration          | Object  |       | イメージに関する設定情報 |
|ImageRepositoryType         | String  | ○    | イメージレポジトリの種類(`ECR` or `ECR_PUBLIC`)|

|ImageConfiguration Field    | 型      | 必須  | 内容  |
|:---                        | :---:   | :---: | :---  |
|RuntimeEnvironmentVariables | Json    |       | 環境変数(AWSAPPRUNNERは使用不可) |
|StartCommand                | String  |       | Dockerイメージの起動コマンド(上書きしたい場合) |
|Port                        | String  |       | 開放するポート(0〜51200から1つ) |



# 使ってみての所管

直感的な感想は「もうちょっと使いやすくならんかなぁ…」という感じでしたね。  
Heroku使っていた人の多くが「細かいことなんていいからWebサービスのトライアルやりたい」という意見でしょうから、いちいちIAMやVPCの設定するのが億劫に感じます。  
また、設定に関してもサービス作成後の初回ビルドで失敗した場合、設定変更してリトライということが出来ず、サービスを削除して作り直しになりました。  
エクスポートの機能もなく、マネジメントコンソールでは純粋な「設定書き直し」が発生するので利便性が悪いですね。。。  

