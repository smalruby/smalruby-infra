# GitHub Actions用AWS OIDC設定手順

## 概要

GitHub ActionsからAWSリソースにアクセスする際、従来のIAMユーザーのアクセスキー・シークレットキーの代わりに、OIDC（OpenID Connect）を使用した一時的な認証を行う設定手順です。

これにより以下の利点があります：
- **セキュリティ向上**: 長期間有効なクレデンシャルを保存する必要がない
- **自動ローテーション**: トークンは短期間で自動的に無効化される
- **最小権限原則**: 特定のリポジトリ・ブランチからのみアクセス可能

## 手順1: AWS Identity Provider（OIDC）の作成

### 1.1 AWSマネジメントコンソールにログイン
- IAM サービスに移動

### 1.2 Identity Provider作成
1. **左メニュー「Identity providers」をクリック**
2. **「Add provider」ボタンをクリック**
3. **Provider type**: 「OpenID Connect」を選択
4. **Provider URL**: `https://token.actions.githubusercontent.com` を入力
5. **Audience**: `sts.amazonaws.com` を入力
6. **「Get thumbprint」をクリック**して証明書のサムプリントを取得
7. **「Add provider」をクリック**

## 手順2: IAMロールの作成

### 2.1 新しいロール作成
1. **IAM → Roles → 「Create role」**
2. **Trusted entity type**: 「Web identity」を選択
3. **Identity provider**: 先ほど作成したGitHub OIDCプロバイダーを選択
4. **Audience**: `sts.amazonaws.com` を選択

### 2.2 信頼関係の設定
**「Next」をクリック後、信頼関係を以下のように設定:**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<AWSアカウントID>:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:smalruby/smalruby-infra:*"
                }
            }
        }
    ]
}
```

**重要**: `<AWSアカウントID>` は実際のAWSアカウントIDに置き換えてください。

### 2.3 権限ポリシーの追加
デプロイに必要な権限を持つポリシーを添付します：

#### 2.3.1 Lambda関数管理権限
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:CreateFunction",
                "lambda:UpdateFunctionCode",
                "lambda:UpdateFunctionConfiguration",
                "lambda:DeleteFunction",
                "lambda:GetFunction",
                "lambda:ListFunctions",
                "lambda:AddPermission",
                "lambda:RemovePermission"
            ],
            "Resource": "*"
        }
    ]
}
```

#### 2.3.2 API Gateway管理権限
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "apigateway:*"
            ],
            "Resource": "*"
        }
    ]
}
```

#### 2.3.3 CloudFormation管理権限
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:UpdateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:DescribeStackEvents",
                "cloudformation:DescribeStackResources",
                "cloudformation:GetTemplate",
                "cloudformation:ValidateTemplate",
                "cloudformation:CreateChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:DeleteChangeSet"
            ],
            "Resource": "*"
        }
    ]
}
```

#### 2.3.4 S3とIAM権限
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:PutBucketVersioning"
            ],
            "Resource": [
                "arn:aws:s3:::aws-sam-cli-managed-default-samclisourcebucket-*",
                "arn:aws:s3:::aws-sam-cli-managed-default-samclisourcebucket-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:PassRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy"
            ],
            "Resource": "*"
        }
    ]
}
```

### 2.4 ロール名設定
- **Role name**: `GitHubActions-smalruby-infra-deploy` （推奨）
- **Description**: `Role for GitHub Actions to deploy smalruby infrastructure`

### 2.5 ロール作成完了
「Create role」をクリックしてロールを作成します。

## 手順3: GitHub Secretsの設定

### 3.1 リポジトリのSecrets設定
1. **GitHubリポジトリ「smalruby/smalruby-infra」に移動**
2. **Settings → Secrets and variables → Actions**
3. **「New repository secret」をクリック**

### 3.2 必要なSecret
以下のSecretを追加：

| Secret名 | 値 | 説明 |
|----------|---|------|
| `AWS_ROLE_ARN` | `arn:aws:iam::<AWSアカウントID>:role/GitHubActions-smalruby-infra-deploy` | 作成したIAMロールのARN |

**注意**: `<AWSアカウントID>` は実際のAWSアカウントIDに置き換えてください。

### 3.3 従来のSecretsの削除（推奨）
OIDCが正常に動作することを確認後、以下の従来のSecretsは削除できます：
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## 手順4: デプロイテスト

### 4.1 GitHub Actionsの実行
mainブランチにpushしてGitHub Actionsが正常に実行されることを確認します。

### 4.2 ログの確認
GitHub Actions実行ログで以下を確認：
- OIDC認証が成功している
- AWS CLIコマンドが正常に実行されている
- デプロイが完了している

## 設定完了後の利点

✅ **セキュリティ向上**: 長期クレデンシャルの漏洩リスクなし
✅ **自動管理**: トークンの自動ローテーション
✅ **アクセス制御**: 特定リポジトリ・ブランチからのみアクセス可能
✅ **監査**: CloudTrailでアクセスログが記録される

## トラブルシューティング

### エラー例1: "Not authorized to perform sts:AssumeRoleWithWebIdentity"
**原因**: 信頼関係の設定が正しくない
**主な問題**:
- Actionが `sts:AssumeRole` になっている（正：`sts:AssumeRoleWithWebIdentity`）
- 条件が厳しすぎる（推奨：`repo:smalruby/smalruby-infra:*`）
- リポジトリ名・ブランチ名の誤り

**対処法**:
1. IAMロールの信頼関係を確認
2. `"Action": "sts:AssumeRoleWithWebIdentity"` になっているか確認
3. 条件が `"repo:smalruby/smalruby-infra:*"` になっているか確認

**修正方法**:
AWSマネジメントコンソールのIAM → Roles → GitHubActions-smalruby-infra-deploy → Trust relationships タブで信頼関係を編集してください。

### エラー例2: "Access Denied"
**原因**: ロールに必要な権限がない
**対処**: ロールに適切なポリシーが添付されているか確認

### エラー例3: "Invalid identity token"
**原因**: GitHub Actionsの設定が正しくない
**対処**: `permissions`セクションに`id-token: write`があるか確認

### エラー例4: "OIDC Provider not found"
**原因**: OIDC Identity Providerが作成されていない
**対処**: 手順1.2に従ってOIDC Providerを作成

### デバッグ手順
1. **OIDC Provider確認**: AWSマネジメントコンソール → IAM → Identity providers で確認
2. **ロール存在確認**: AWSマネジメントコンソール → IAM → Roles で「GitHubActions-smalruby-infra-deploy」を検索
3. **信頼関係確認**: 該当ロールの Trust relationships タブで設定内容を確認
4. **権限確認**: 該当ロールの Permissions タブで必要なポリシーが添付されているか確認
