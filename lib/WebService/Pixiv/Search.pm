package WebService::Pixiv::Search;
use strict;
use warnings;
use base qw(WebService::Pixiv::Base);
use URI;
use URI::Escape;
use Web::Scraper;
use WebService::Pixiv::Illust;

use Class::Accessor::Lite
    rw => [ qw(
       tags
    ) ];


sub base_uri {
    return 'http://www.pixiv.net/search.php';
}

sub pager {
    return 20;
}

sub count {
    my ($self) = @_;

    my $res = $self->_get_res(0);

    my $count = $res->{count};
    $count =~ s/,//g;

    $count;
}

sub selector {
    my $selector_count = q|ul.sub > li > span.count|;
    my $selector_illust_id = q|ul[class="images autopagerize_page_element"] > li > a > p > img|;

    scraper {
	process $selector_count, count => 'TEXT',
	process $selector_illust_id, 'illust_id[]' => '@data-src',
    };
}

sub _get_content {
    my ($self, $i) = @_;

    my $uri = URI->new($self->base_uri);
    my %query = (
	word => join(' ', @{$self->tags}),
	s_mode => 's_tag',
    );

    if ($i > 0) {
	$query{p} = $i + 1;
    }

    $uri->query_form(%query);

    my $res = $self->mech->get($uri);
    if ( ! $res->is_success ) {
	die "Can't get content: " . $res->req->uri;
    }
    sleep $self->delay;

    $self->mech->content;
}

sub response {
    my ($self, $res, $item_num) = @_;

    my $href = $res->{illust_id}->[$item_num];
    $href =~ /(\d+)_s/;
    my $id = $1;

    WebService::Pixiv::Illust->new(
	mech => $self->mech,
	id   => $id,
    );
}

1;
