package WebService::Pixiv::MemberIllust;
use strict;
use warnings;
use base qw(WebService::Pixiv::Base);
use Web::Scraper;
use WebService::Pixiv::Illust;


sub base_uri {
    return 'http://www.pixiv.net/member_illust.php';
}

sub pager {
    return 20;
}

sub illust_id {
    my ($self, $illust_id) = @_;

    my @list;
    for my $href ( @{ $illust_id } ) {
	if ( $href =~ /member_illust\.php/ ) {
	    push @list, $href;
	}
    }

    return \@list;
}

sub selector {
    my $self = shift;

    my ($selector_count, $selector_illust_id);
    if ($self->id == $self->my_user_id) {
	$selector_count = qq|div.two_column_top3 > h3 > span|;
	$selector_illust_id = qq|li[id^="li_"] > a|;
    } else {
	$selector_count = qq|div.two_column_body > h3 > span|;
	$selector_illust_id = qq|li[id^="li_"] > a|;
    }

    scraper {
	process $selector_count, count => 'TEXT',
	process $selector_illust_id, 'illust_id[]' => '@href',
    };
}


sub response {
    my ($self, $res, $item_num) = @_;

    my $href = $self->illust_id($res->{illust_id})->[$item_num];
    $href =~ /illust_id=(\d+)/;

    my $id = $1;

    WebService::Pixiv::Illust->new(
	mech => $self->mech,
	id   => $id,
    );
}

1;
