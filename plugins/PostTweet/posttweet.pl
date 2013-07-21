package MT::Plugin::PostTweet;

use strict;
use base qw( MT::Plugin );
use MT;
use MT::Plugin;
use MT::Util qw(encode_url);

our $PLUGIN_NAME = 'PostTweet';
our $VERSION = '1.0.3';
our $DEBUG = 0;

our $CONSUMER_KEY = 'JFAOihHR5GtsonDhjvxA';
our $CONSUMER_SECRET = '8FB4pPugwoAcUI2WkjaQAYpuaGgH9707HMqsdjOEw';

sub BEGIN {
	if (MT->version_number < 4.2) {
		require File::Spec;
		require File::Basename;
		my $dir = File::Basename::dirname(File::Spec->rel2abs(__FILE__));
		unshift @INC, File::Spec->catdir($dir, 'extlib');
	}
}

my $plugin = new MT::Plugin::PostTweet({
	name => $PLUGIN_NAME,
	id => 'posttweet',
	key => __PACKAGE__,
	version => $VERSION,
	description => "<MT_TRANS phrase='Post entry/page title and shortened permalink to Twitter'>",
	author_name => 'M-Logic, Inc.',
	author_link => 'http://m-logic.co.jp/',
	doc_link => 'http://m-logic.co.jp/mt-plugins/posttweet/docs/' . $VERSION . '/posttweet.html',
	l10n_class => 'PostTweet::L10N',
	blog_config_template => \&blog_config_template,
	settings => new MT::PluginSettings([
		['posttweet_only_firstrelease', { Default => 0 } ],
		['posttweet_ignore_newpost', { Default => 0 } ],
		['posttweet_url_shortener', { Default => 'tinyurl' } ],
		['posttweet_bitly_username'],
		['posttweet_bitly_apikey'],
		['posttweet_last_status'],
		['posttweet_format_template', { Default => 'PostTweet Message Format' } ],
		['posttweet_access_token'],
		['posttweet_access_token_secret'],
		['posttweet_plugin_enable', {Default => 1, Scope => 'blog'} ],
	]),
	registry => {
		callbacks => {
			'cms_post_save.entry' => \&post_save_entry,
			'cms_post_save.page' => \&post_save_entry,
			'scheduled_post_published' => \&post_save_entry,
			'api_post_save.entry' => \&api_post_save_entry,
			'api_post_save.page' => \&api_post_save_entry,
			'MT::App::CMS::template_source.edit_entry'
				=> \&edit_entry_source,
			'MT::App::CMS::template_param.edit_entry'
				=> \&edit_entry_param,
		},
		applications => {
			cms => {
				methods => {
					'repost_posttweet' => \&repost_posttweet,
					'oauth_posttweet' => \&oauth_posttweet,
					'get_access_token_posttweet' => \&get_access_token_posttweet,
				},
			},
		},
		tags => {
			function => {
				'EntryShortenedPermalink' => \&hdlr_shortened_permalink,
			},
		},
	},
});

if (MT->version_number >= 4.1) { # required MT4.1
    MT->add_plugin($plugin);
}

sub instance { $plugin; }

sub doLog {
	my ($msg) = @_; 
	use MT::Log;
	my $log = MT::Log->new; 
	if ( defined( $msg ) ) { 
		$log->message( $msg ); 
	}
	$log->save or die $log->errstr;
	return;
}

sub is_mt4 {
	return (substr(MT->version_number, 0, 2) eq '4.');
}

sub is_mt5 {
	return (substr(MT->version_number, 0, 2) eq '5.');
}

sub req_modules {
	my $plugin = shift;
	my @req_modules;
	if (eval { require LWP::UserAgent; 1 }) {
		eval { my $prot = LWP::Protocol::create('https'); };
		if ($@) {
			doLog($@) if ($DEBUG);
			push @req_modules, $plugin->translate('Crypt::SSLeay or IO::Socket::SSL');
		}
		unless (eval { require Net::OAuth::Simple; 1 }) {
			doLog($@) if ($DEBUG);
			push @req_modules, 'Net::OAuth::Simple';
		}
	} else {
		push @req_modules, 'LWP';
	}
	if (eval { require Digest::SHA1; 1 }) {
		unless (eval { require Digest::HMAC_SHA1; 1 }) {
			doLog($@) if ($DEBUG);
			push @req_modules, 'Digest::HMAC_SHA1';
		}
	} else {
		doLog($@) if ($DEBUG);
		push @req_modules, 'Digest::SHA1';
	}
	@req_modules;
}

sub blog_config_template {
	my $plugin = shift;
	my ($param,  $scope) = @_;
	my $tmpl;

	if (is_mt4()) {
		$tmpl = $plugin->load_tmpl('blog_config_mt4.tmpl');
	} else {
		$tmpl = $plugin->load_tmpl('blog_config_mt5.tmpl');
	}
	my $req_modules = join ', ', $plugin->req_modules;
	$tmpl->param('posttweet_req_modules' => $req_modules);
	my $blog_id = $scope;
	$blog_id =~ s/blog://;
	$tmpl->param('blog_id' => $blog_id);
	return $tmpl; 
}

sub save_config {
	my $plugin = shift;
	my ($param, $scope) = @_;
	$param->{'posttweet_access_token'} = $plugin->get_config_value('posttweet_access_token', $scope);
	$param->{'posttweet_access_token_secret'} = $plugin->get_config_value('posttweet_access_token_secret', $scope);
	my $ret = $plugin->SUPER::save_config($param, $scope);
	$ret;
}

sub get_setting {
	my ($plugin, $key, $blog_id) = @_;
	my $scope = $blog_id  ? 'blog:'.$blog_id : 'system';
	return $plugin->get_config_value($key, $scope);
}

sub posttweet_plugin_enable {
	my $plugin = shift;
	return $plugin->get_setting('posttweet_plugin_enable', @_);
}

sub posttweet_access_token {
	my $plugin = shift;
	return $plugin->get_setting('posttweet_access_token', @_);
}

sub posttweet_access_token_secret {
	my $plugin = shift;
	return $plugin->get_setting('posttweet_access_token_secret', @_);
}

sub posttweet_only_firstrelease {
	my $plugin = shift;
	return $plugin->get_setting('posttweet_only_firstrelease', @_);
}

sub posttweet_ignore_newpost {
	my $plugin = shift;
	return $plugin->get_setting('posttweet_ignore_newpost', @_);
}

sub posttweet_url_shortener {
	my $plugin = shift;
	return $plugin->get_setting('posttweet_url_shortener', @_);
}

sub posttweet_bitly_username {
	my $plugin = shift;
	return $plugin->get_setting('posttweet_bitly_username', @_);
}

sub posttweet_bitly_apikey {
	my $plugin = shift;
	return $plugin->get_setting('posttweet_bitly_apikey', @_);
}

sub posttweet_format_template {
	my $plugin = shift;
	return $plugin->get_setting('posttweet_format_template', @_);
}

sub posttweet_consumer_key {
	my $plugin = shift;
	return $CONSUMER_KEY;
}

sub posttweet_consumer_secret {
	my $plugin = shift;
	return $CONSUMER_SECRET;
}

sub get_last_status {
	my ($plugin, $obj, $clear) = @_;
	my $map = $plugin->get_config_value('posttweet_last_status')
		or return;
	my $value = $map->{$obj->id};
	if($clear && exists $map->{$obj->id}) {
		delete $map->{$obj->id};
		$plugin->set_config_value('posttweet_last_status', $map);
	}
	return $value;
}

sub set_last_status {
	my ($plugin, $obj, $value) = @_;
	my $map = $plugin->get_config_value('posttweet_last_status');
	unless($map) {
		$map = {};
	}
	$map->{$obj->id} = $value;
	return $plugin->set_config_value('posttweet_last_status', $map);
}

sub clear_last_status {
	my ($plugin, $obj) = @_;
	my $map = $plugin->get_config_value('posttweet_last_status')
		or return;
	delete $map->{$obj->id} if exists $map->{$obj->id};
	return $plugin->set_config_value('posttweet_last_status', $map);
}

sub log_error {
	my ($plugin, $obj, $msg) = @_;
	die "no required args, obj or msg." if !$obj || !$msg;
	$msg = "PostTweet: " . $msg;
	$plugin->set_last_status($obj, $msg);
	return doLog($msg);
}

sub log_success {
	my ($plugin, $obj, $msg) = @_;
	die "No required arg, obj." if !$obj;
	$msg = "ok" unless $msg;
	$plugin->set_last_status($obj, $msg);
	return 1;
}

use constant MAX_MESSAGE_LENGTH => 140;
use constant CONT_STR_LENGTH => 3;
use constant CONT_STR => '...';

sub api_post_save_entry {
	my ($eh, $app, $obj, $original) = @_;
	my $blog_id = $obj->blog_id;

	return unless $plugin->posttweet_plugin_enable($blog_id);

	my $ignore_newpost = $plugin->posttweet_ignore_newpost($blog_id);
	return if $ignore_newpost && $original && $original->id != $obj->id;
	return post_save_entry($eh, $app, $obj, $original);
}

sub post_save_entry {
	my ($eh, $app, $obj, $original, $repost) = @_;
	return $plugin->log_error(
		$obj, $plugin->translate("Object is not Entry."))
		if ref $obj ne 'MT::Entry' && ref $obj ne 'MT::Page';
	my $blog_id = $obj->blog_id;
	return unless $plugin->posttweet_plugin_enable($blog_id);

	require MT::Entry;
	return 1 unless $obj->status == MT::Entry::RELEASE();
	my $only_firstrelease = $plugin->posttweet_only_firstrelease($blog_id);
	return 1 if !$repost && $only_firstrelease
		&& $original && $original->status == MT::Entry::RELEASE();
	my $access_token = $plugin->posttweet_access_token($blog_id)
		or return $plugin->log_error(
			$obj, $plugin->translate("Authorize error"));
	my $msg = $plugin->get_message($obj)
		or return $plugin->log_error(
			$obj, $plugin->translate("Failed to create a message, ([_1])", $plugin->errstr));
	unless($plugin->update_twitter($msg, $obj)) {
		return $plugin->log_error(
			$obj, $plugin->translate("Failed to post, ([_1])", $plugin->errstr));
	}
	return $plugin->log_success($obj, "ok");
}

sub get_message {
	my ($plugin, $obj) = @_;
	my $msg = $plugin->get_templated_message($obj);
	return if !defined $msg && $plugin->errstr;
	return $msg if $msg;
	my $blog_id = $obj->blog_id;
	require MT::Entry;
	require MT::I18N;
	my $title = MT::I18N::encode_text($obj->title, undef, 'utf-8');
	my $title_length = MT::I18N::length_text($title);
	my $url = $plugin->get_shorturl($obj->permalink, $blog_id)
		or return;
	$url = $url ? ' (' . $url . ')' : '';
	my $url_length = $url ? MT::I18N::length_text($url) : 0;
	require MT::Tag;
	my @tags = $obj->tags;
	@tags = grep { m!^#! } @tags;
	my $tags = MT::Tag->join(' ', @tags);
	$tags = $tags ? ' ' . $tags : '';
	my $tags_length = $tags ? MT::I18N::length_text($tags) : 0;
	my $info_length = $url_length + $tags_length;
	if($title_length + $info_length > MAX_MESSAGE_LENGTH) {
		$title_length = (MAX_MESSAGE_LENGTH - $info_length - CONT_STR_LENGTH);
		$title = MT::I18N::substr_text($title, 0, $title_length) . CONT_STR;
	}
	$msg = ($title . $url . $tags);
	return $msg;
}

sub get_templated_message {
	my ($plugin, $obj) = @_;
	#my $tmpl_name = 'PostTweet Message';
	my $blog = $obj->blog;
	my $tmpl_name = $plugin->posttweet_format_template($blog->id);
	require MT::Template;
	my $tmpl;
	if($tmpl_name) {
		my @tmpl = MT::Template->load({
			($blog ? (blog_id => [$blog->id, 0]) : (blog_id => 0)),
			name => $tmpl_name,
			type => 'custom',
		});
		if (@tmpl) {
			if (scalar @tmpl > 1) {
				$tmpl = $tmpl[0]->blog_id ? $tmpl[0] : $tmpl[1];
			} else {
				$tmpl = $tmpl[0];
			}
		}
	}
	$tmpl = $plugin->load_tmpl('message_format.tmpl') unless $tmpl;
	return unless $tmpl;
	my $app = MT->instance;
	$app->set_default_tmpl_params($tmpl);
	my $ctx = $tmpl->context;
	$ctx->stash('posttweet', 1);
	$ctx->stash('blog', $blog);
	$ctx->stash('entry', $obj);
	my $out = $tmpl->build($ctx);
	if(defined $out) {
		require MT::I18N;
		my $length = MT::I18N::length_text($out);
		if($length > MAX_MESSAGE_LENGTH) {
			$out = MT::I18N::substr_text($out, 0, (MAX_MESSAGE_LENGTH - $length));
		}
	}
	else {
		return $plugin->error($app->errstr);
	}
	return $out;
}

sub get_shorturl {
	my ($plugin, $url, $blog_id) = @_;
	return $plugin->trans_error("No url or blog id.") unless $url && $blog_id;
	my $shorturl = '';
	my $shortener = $plugin->posttweet_url_shortener($blog_id)
		or return $plugin->trans_error("URL Shortener not specified.");
	if($shortener eq 'tinyurl') {
		$shorturl = $plugin->shorten_by_tinyurl($url)
			or return;
	}
	elsif($shortener eq 'bitly' || $shortener eq 'jmp') {
		my $username = $plugin->posttweet_bitly_username($blog_id)
			or return $plugin->trans_error("bit.ly API Login not specified.");
		my $apikey = $plugin->posttweet_bitly_apikey($blog_id)
			or return $plugin->trans_error("bit.ly API Key not specified.");
		$shorturl = $plugin->shorten_by_bitly($url, $username, $apikey, $shortener)
			or return;
	}
	return $shorturl;
}

sub shorten_by_bitly {
	my ($plugin, $url, $username, $apikey, $domain) = @_;
	return $plugin->trans_error("No url, username or apikey.") unless $url && $username && $apikey;
	return 'http://bit.ly/xxxxxx' if ($plugin->{preview_mode} && $domain eq 'bitly');
	return 'http://j.mp/xxxxxx' if ($plugin->{preview_mode} && $domain eq 'jmp');
	my $apiurl = "http://api.bit.ly/v3/shorten?";
	$apiurl .="&longUrl=" . encode_url($url);
	$apiurl .= "&login=$username&apiKey=$apikey";
	$apiurl .= "&domain=j.mp" if ($domain eq 'jmp');
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new
		or $plugin->trans_error("Failed to create LWP::UserAgent object.");
	my $res = $ua->get($apiurl);
	return $plugin->trans_error("Failed to get response from [_1], ([_2])", "bit.ly", $res->status_line) unless $res->is_success;
	my $result = $res->content;
	require JSON;
	my $obj = defined &JSON::from_json ? JSON::from_json($result) : JSON::jsonToObj($result)
		or return $plugin->trans_error("Failed to parse result.");
	return $plugin->trans_error("Failed to get shortened url, ([_1])", $obj->{errorCode}) if $obj->{errorCode};
	my $shorturl = exists $obj->{data}->{url}
		? $obj->{data}->{url} : '';
	return $shorturl;
}

sub shorten_by_tinyurl {
	my ($plugin, $url) = @_;
	return $plugin->trans_error("No url") unless $url;
	return 'http://tinyurl.com/xxxxxx' if $plugin->{preview_mode};
	my $api_url = 'http://tinyurl.com/api-create.php?url=';
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new
		or $plugin->trans_error("Failed to create LWP::UserAgent object.");
	my $res = $ua->get($api_url.$url);
	return $plugin->trans_error("Failed to get response from [_1], ([_2])", "tinyurl", $res->status_line) unless $res->is_success;
	my $tinyurl = $res->content;
	return $tinyurl;
}

sub update_twitter {
	my ($plugin, $msg, $obj) = @_;

	require Net::OAuth::Simple;

	my $blog_id = $obj->blog_id;
	my $access_token = $plugin->posttweet_access_token($blog_id);
	my $access_token_secret = $plugin->posttweet_access_token_secret($blog_id);
	my %tokens  = (
		'access_token' => $access_token,
		'access_token_secret' => $access_token_secret,
		'consumer_key' => $plugin->posttweet_consumer_key($blog_id) ,
		'consumer_secret' => $plugin->posttweet_consumer_secret($blog_id),
	);
	my $nos = Net::OAuth::Simple->new(
		tokens => \%tokens,
		protocol_version => '1.0a',
		urls => {
			authorization_url => 'https://twitter.com/oauth/authorize',
			request_token_url => 'https://twitter.com/oauth/request_token',
			access_token_url  => 'https://twitter.com/oauth/access_token',
		}
	);
	return $plugin->trans_error("Authorize error") unless $nos->authorized;
	my $url  = "http://api.twitter.com/1/statuses/update.xml";
	my %params = ('status' => $msg);
	my $response;
	eval { $response = $nos->make_restricted_request($url, 'POST', %params); };
	if ($@) {
		my $err = $@;
		return $plugin->trans_error("Failed to get response from [_1], ([_2])", "twitter", $err);
	}
	return $plugin->trans_error("Failed to get response from [_1], ([_2])", "twitter", $response->status_line) unless $response->is_success;
	return 1;
}

#
sub edit_entry_source {
	my ($cb, $app, $tmpl_ref) = @_;

	my $blog = $app->blog; 
	my $blog_id = $blog->id; 
	return unless $plugin->posttweet_plugin_enable($blog_id);

	my $pattern = quotemeta(<<'HTML');
    <div id="msg-block">
HTML
	my $replacement = $plugin->translate_templatized(<<'HTML');
    <mt:if name="posted">
      <mtapp:statusmsg
        id="posted"
        class="success">
        <mt:if name="object_type" eq="entry">
          <__trans phrase="This entry has been posted to twitter.">
        <mt:else>
          <__trans phrase="This page has been posted to twitter.">
        </mt:if>
      </mtapp:statusmsg>
    </mt:if>
    <mt:if name="post_error">
      <mtapp:statusmsg
        id="post-error"
        class="alert">
        <__trans phrase="Failed to post to twitter.">
      </mtapp:statusmsg>
    </mt:if>
HTML
	$$tmpl_ref =~ s!($pattern)!$1$replacement!;

	$pattern = quotemeta(<<'HTML');
<mt:setvarblock name="js_include" append="1">
HTML
	$replacement = $plugin->translate_templatized(<<'HTML');
<mt:setvarblock name="related_content" append="1">
<mt:unless name="new_object">
<div id="posttweet-field">
  <mtapp:widget
    id="posttweet-widget"
    label="<__trans phrase="PostTweet">">
    <mtapp:setting
      id="posttweet-preview"
      label="<__trans phrase="Message Preview">"
      label_class="top-label">
        <div id="posttweet-preview-area"
          name="posttweet-preview-area"
          class="full-width"
          style="border: 1px solid #CCCCCC; padding: 0 4px;">
          <$mt:var name="posttweet_message_preview"$></div>
    </mtapp:setting>
    <mtapp:setting
      id="posttweet-repost"
      label="<__trans phrase="Repost to Twitter">"
      label_class="no-header">
        <button mt:mode="repost_posttweet" name="posttweet_repost"
          type="submit"
          title="<__trans phrase="Repost">">
          <__trans phrase="Repost"></button>
    </mtapp:setting>
  </mtapp:widget>
</div>
</mt:unless>
</mt:setvarblock>
HTML
	$$tmpl_ref =~ s!($pattern)!$replacement$1!;

	1;
}

sub edit_entry_param {
	my ($cb, $app, $param) = @_;
	my $q = $app->{'query'};
	my $type = $q->param('_type');
	my $obj_id = $q->param('id');
	my $blog_id = $q->param('blog_id');

	return unless $plugin->posttweet_plugin_enable($blog_id);

	my $class = $app->model($type) || 'entry';
	my $obj = $class->load($obj_id) or
		return $app->error(
			$app->translate('Can\'t load [_1] #[_2].', $class, $obj_id));
	my $last_status = $plugin->get_last_status($obj, 1);
	if($last_status eq "ok" || $q->param('posted')) {
		$param->{posted} = 1;
	}
	if($last_status =~ m!^PostTweet! || $q->param('post_error')) {
		$param->{post_error} = 1;
	}
	my $message = '';
	eval {
		$plugin->{preview_mode} = 1;
		$message = $plugin->get_message($obj) || '';
	};
	if($@) {
	log_error("edit_entry_param: eval err=$@, msg=$message");
	}
	$plugin->{preview_mode} = 0;
	$param->{posttweet_message_preview} = $message;
}

sub repost_posttweet {
	my $app = shift;
	my $q = $app->{query};
	my $type = $q->param('_type');
	my $obj_id = $q->param('id');
	my $blog_id = $q->param('blog_id');
	my $class = $app->model($type) || 'entry';
	my $obj = $class->load($obj_id) or
		return $app->error(
			$app->translate('Can\'t load [_1] #[_2].', $class, $obj_id));
	my $org = $obj->clone;
	my $repost = 1;
	my $res = post_save_entry(undef, $app, $obj, $org, $repost);
	return $app->redirect(
		$app->uri(mode => 'view',
				 args => {
					'_type' => $type,
					id => $obj_id,
					blog_id => $blog_id,
				}
			));
}

sub hdlr_shortened_permalink {
	my ($ctx, $args) = @_;
	my $tag = $ctx->stash('tag');
	my $tag_name = 'mt' . $tag unless $tag =~ m/^MT/i;
	return $ctx->error($plugin->translate(
		'You used an \'[_1]\' tag outside of the context of an PostTweet message.', $tag_name))
		unless $ctx->stash('posttweet');
	my $name = exists $args->{add_query} ? delete $args->{add_query} : '';
	$name = $ctx->var($name) if $name =~ m/^\$/;;
	my $permalink = $ctx->tag('entrypermalink', $args);
	if ($name) {
		my $value = $ctx->var($name) || {};
		require URI;
		my $uri = URI->new($permalink);
		if ('HASH' eq ref($value)) {
			$uri->query_form($value);
		}
		elsif (!ref($value)) {
			$uri->query_form($name => $value);
		}
		#else {
		#	return $ctx->error(MT->translate( "[_1] is not a hash.", $name ))
		#}
		$permalink = $uri->as_string;
	}
	my $shorturl;
	if($permalink) {
		my $blog = $ctx->stash('blog');
		$shorturl = $plugin->get_shorturl($permalink, $blog->id)
			or return $ctx->error($plugin->errstr);
	}
	return $shorturl ? $shorturl : $permalink;
}

sub oauth_posttweet {
	my $app = shift;
	my $q = $app->{query};
	my $blog_id = $q->param('blog_id');
	
	my $tmpl;
	
	if (is_mt4()) {
		$tmpl = $plugin->load_tmpl('oauth_start_mt4.tmpl');
	} else {
		$tmpl = $plugin->load_tmpl('oauth_start_mt5.tmpl');
	}
	
	require Net::OAuth::Simple;
	my %tokens = (
		'consumer_key' => $plugin->posttweet_consumer_key($blog_id) ,
		'consumer_secret' => $plugin->posttweet_consumer_secret($blog_id),
	);

	my $nos = Net::OAuth::Simple->new(
		tokens => \%tokens,
		protocol_version => '1.0',
		urls => {
			authorization_url => 'https://twitter.com/oauth/authorize',
			request_token_url => 'https://twitter.com/oauth/request_token',
			access_token_url  => 'https://twitter.com/oauth/access_token',
		}
	);

	my $url;
	eval { $url = $nos->get_authorization_url(); };
	if ($@) {
		my $err = $@;
		$tmpl->param('error_authorization' => 1);
	} else {
		my $request_token = $nos->request_token;
		my $request_token_secret = $nos->request_token_secret;
		$tmpl->param('access_url' => $url);
		$tmpl->param('request_token' => $request_token);
		$tmpl->param('request_token_secret' => $request_token_secret);
	}
	return $tmpl; 
}

sub get_access_token_posttweet {
	my $app = shift;
	my $q = $app->{query};
	my $blog_id = $q->param('blog_id');

	my $new_pin = $q->param('posttweet_pin') || q{};
	my $tmpl;
	if (is_mt4()) {
		$tmpl = $plugin->load_tmpl('oauth_complete_mt4.tmpl');
	} else {
		$tmpl = $plugin->load_tmpl('oauth_complete_mt5.tmpl');
	}

	my %tokens  = (
		'consumer_key' => $plugin->posttweet_consumer_key($blog_id) ,
		'consumer_secret' => $plugin->posttweet_consumer_secret($blog_id),
		'request_token' => $q->param('request_token'),
		'request_token_secret' => $q->param('request_token_secret'),
	);

	require Net::OAuth::Simple;
	my $nos = Net::OAuth::Simple->new(
		tokens => \%tokens,
		protocol_version => '1.0a',
		urls => {
			authorization_url => 'https://twitter.com/oauth/authorize',
			request_token_url => 'https://twitter.com/oauth/request_token',
			access_token_url  => 'https://twitter.com/oauth/access_token',
		}
	);
	$nos->verifier($new_pin);
	my ($access_token, $access_token_secret, $user_id, $screen_name);
	eval { ($access_token, $access_token_secret, $user_id, $screen_name) =  $nos->request_access_token(); };
	if ($@) {
		my $err = $@;
		$tmpl->param('error_verification' => 1);
	} else {
		$tmpl->param('verified_screen_name' => $screen_name);
		$tmpl->param('verified_user_id' => $user_id);
		$plugin->set_config_value('posttweet_access_token', $access_token, 'blog:' . $blog_id);
		$plugin->set_config_value('posttweet_access_token_secret', $access_token_secret, 'blog:' . $blog_id);
	}
	$tmpl;
}

1;
