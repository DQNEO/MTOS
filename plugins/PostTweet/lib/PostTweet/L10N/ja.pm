package PostTweet::L10N::ja;

use strict;
use base 'PostTweet::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (
    'Post entry/page title and shortened permalink to Twitter' => 'ブログ記事/ウェブページのタイトルとパーマリンクの短縮URLをTwitterに投稿します。',
    'Post when:' => '投稿:',
    'Entry/Page status changed from Unpublished to Published.' => 'ブログ記事/ウェブページの状態を未公開(下書き)から公開に変更した場合に投稿します。',
    'Experimental Options:' => '実験的なオプション:',
    'Ignore XML-RPC newPost method.' => 'XML-RPC newPostメソッドを無視します。',
    'URL Shortener:' => 'URL短縮サービス:',
    'bit.ly API Login:' => 'bit.ly API Login:',
    'bit.ly API Key:' => 'bit.ly API Key:',
    'Specify your bit.ly API Login name.' => 'bit.ly APIログイン名を指定してください。',
    'Specify your bit.ly API Key.' => 'bit.ly APIキーを指定してください。',
    'Format Template:' => 'フォーマットテンプレート名:',
    'Object is not Entry.' => 'Entryオブジェクトではありません。',
    'Failed to create a message, ([_1])' => 'メッセージの作成に失敗しました。([_1])',
    'Failed to post, ([_1])' => 'Twitterへの投稿に失敗しました。([_1])',
    'No url or blog id.' => 'URLまたはブログIDが指定されていません。',
    'URL Shortener not specified.' => 'URL短縮サービスが指定されていません。',
    'bit.ly API Login not specified.' => 'bit.ly API ログイン名が指定されていません。',
    'bit.ly API Key not specified.' => 'bit.ly API キーが指定されていません。',
    'No url, username or apikey.' => 'URLまたはユーザ名、APIキーが指定されていません。',
    'Failed to create LWP::UserAgent object.' => 'LWP::UserAgentの生成に失敗しました。',
    'Failed to get response from [_1], ([_2])' => '[_1]から応答を得られません。([_2])',
    'Failed to parse result.' => '受信内容の解析に失敗しました。',
    'Failed to get shortened url, ([_1])' => '短縮URLの取得に失敗しました。([_1])',
    'This entry has been posted to twitter.' => 'ブログ記事をTwitterへ投稿しました。',
    'This page has been posted to twitter.' => 'ウェブページをTwitterへ投稿しました。',
    'Failed to post to twitter.' => 'Twitterへの投稿に失敗しました。',
    'Repost' => '再投稿',
    'Repost to Twitter' => 'Twitterへ再投稿',
    'Message Preview' => 'メッセージの確認',
    'Authorize error' => '認証エラー',
    'Authentication:' => '認証:',
    'Authorize this plugin and enter the PIN#.' => 'このプラグインを認証してから、PIN番号を入力してください。',
    'Get PIN#' => 'PIN番号を取得する',
    'Done' => '実行',
    'OAuth authentication' => 'OAuthによる認証',
    'Authentication succeeded' => '認証に成功しました',
    'Authentication failed' => '認証に失敗しました',
    'Enable:' => '有効:',
    'Enable this plugin in this blog.' => 'このブログでプラグインを有効にする',
    'Enable this plugin in this blog/site.' => 'このブログ/サイトでプラグインを有効にする',
    'Crypt::SSLeay or IO::Socket::SSL' => 'Crypt::SSLeay もしくは IO::Socket::SSL',
    'Your server does not have the required modules installed : ' => 'お使いのサーバーで必要なモジュールを読み込めません : ',
);

1;
