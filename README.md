ビットコインアドレスごとの残高を計算します


```
$ mysql -uroot -p
mysql> CREATE DATABASE bitcoin_account_value;
mysql> CREATE USER bitcoin_account_value@localhost IDENTIFIED BY 'password';
mysql> GRANT ALL PRIVILEGES ON bitcoin_account_value.* TO bitcoin_account_value@localhost IDENTIFIED BY 'password';
mysql> CREATE TABLE bitcoin_account_value.`address_balances` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, `address` CHAR(34), `balance` DOUBLE DEFAULT 0.0, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `index_address_balances_on_address` (`address`));
mysql> CREATE TABLE bitcoin_account_value.`heights` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, `height` BIGINT UNSIGNED DEFAULT 0, `created_at` datetime NOT NULL, `updated_at` datetime NOT NULL, PRIMARY KEY (`id`));

$ bundle install --path vendor/bundle

環境変数を設定(address_balance.rbから参照)
BITCOIN_ACCOUNT_BALANCE_USERNAME
BITCOIN_ACCOUNT_BALANCE_PASSWORD
BITCOIN_ACCOUNT_BALANCE_DATABASE

$ bitcoind -daemon
$ bundle exec ruby -I. main.rb
# いつ終わるのかわかりません。パソコンの性能にもよるとはおもいますが3日間くらい動かし続けて2万ブロックくらいです。
```
