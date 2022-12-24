# Docker-Railsテンプレートリポジトリ

Docker上のRails(MySQL・Nginx)環境を構築するためのテンプレートリポジトリです。  

— **目次** —

- [概要](#概要)
  - [パッケージ](#パッケージ)
  - [コミット](#コミット)
  - [ブランチ](#ブランチ)
  - [プロジェクト用の設定](#プロジェクト用の設定)
- [使用方法](#使用方法)

## 概要

### パッケージ

プロジェクト作成時より以下のGemが使用できます。  

- dotenv
- fuctory_bot
- Guard
- Lefthook
- Markdownlint
- Rack CORS Middleware
- RSpec
- Rubocop
- My Git Lint
- Solargraph（devcontainer内のみ）

Lefthookをホストで使用するには別途ローカルにインストールする必要があります。  
[【evilmartians/lefthook】Install lefthook](https://github.com/evilmartians/lefthook/blob/master/docs/install.md)を参考にインストールしてください。  

DockerベースイメージおよびGemが更新可能な場合にDependabotによりプルリクエストが発行されます。  

### コミット

コミットメッセージは[COMMIT_CONVENTION.md](.github/commit/COMMIT_CONVENTION.md)に基づいて作成します。  
これを容易にするため[gitmessage.txt](.github/commit/gitmessage.txt)をコミットメッセージのテンプレートとして使用します。  

### ブランチ

マージされたリモートブランチは自動で削除されるように設定されます。  

### プロジェクト用の設定

プロジェクト名に`backend`という文言を含めると以下の機能が有効になります。  

- ブランチの作成  
  `develop`ブランチが作成されます。  
- `main`と`develop`が保護ブランチになる  
  上記ブランチへ`marge`する際にプルリクエストに対し1件以上の承認が必要になります。  
  また新しいコミットが`push`されたときに古いプルリクエストの承認が却下されるようになります。
- Lefthookの実行コマンド追加  
  [lefthook.yml](lefthook.yml)の`protect-branch`が有効になります。  
  （プロジェクト名に`backend`が含まれていない場合には`protect-branch`は削除されます。）  

## 使用方法

まずこのリポジトリをテンプレートとして新規リポジトリを作成します。  

```terminal
gh repo create <新規リポジトリ名> --public --template P-manBrown/docker-rails-template
```

次のコマンドを実行して作成したリポジトリをローカルにクローンします。  

<details>
  <summary>gitコマンドの場合（クリックして展開）</summary>

```terminal
git clone <URL or SSH key>
```

</details>

<details>
  <summary>ghコマンドの場合（クリックして展開）</summary>

```terminal
gh repo clone <GitHubユーザー名>/<新規リポジトリ名>
```

</details>

プロジェクトルートに移動します。  

```terminal
cd <作成されたディレクトリ>
```

プロジェクト作成の準備をするために次のコマンドを実行します。  

```terminal
bash setup/scripts/prepare-create-pj.sh
```

プロジェクトを作成するために以下の手順を実行します。  

まず以下のファイルを書き換えます。

- `Docker/api/environment/github-credentials.env`
- `Docker/db/environment/mysql.env`

ここで使用するPersonal Access Tokenには以下のスコープが必要です。  

- repo
- read:packages
- read:org

<details>
  <summary>「Dev Containers」を使用する場合（クリックして展開）</summary>

書き換え後「Dev Containers」を起動します。  
コマンドパレットで`Dev Containers: Reopen in Container`を実行します。  
起動完了後コンテナ内で次のコマンドを実行してRailsアプリケーションを作成します。  

```terminal
bash setup/scripts/create-pj.sh
```

</details>

<details>
  <summary>「Dev Containers」を使用しない場合（クリックして展開）</summary>

LefthookをDockerに対応させるため[lefthook-local.yml](setup/config/lefthook-local.yml)をプロジェクトルートに移動します。  

```terminal
mv setup/config/lefthook-local.yml ./
```

次のコマンドを実行してRailsアプリケーションを作成します。  

```terminal
docker compose run --rm --no-deps api bash setup/scripts/create-pj.sh
```

</details>

次に`README.md`を作成します。  

作成後に次のコマンドを実行して「Initial commit」を再作成します。  

```terminal
bash setup/scripts/initial-commit.sh
```
