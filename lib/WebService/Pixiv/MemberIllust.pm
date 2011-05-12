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

sub selector {
    my $selector_count = qq|div.two_column_body > h3 > span|;
    my $selector_illust_id = qq|li[id^="li_"] > a|;

    scraper {
	process $selector_count, count => 'TEXT',
	process $selector_illust_id, 'illust_id[]' => '@href',
    };
}

sub response {
    my ($self, $res, $item_num) = @_;

    my $href = $res->{illust_id}->[$item_num];
    $href =~ /illust_id=(\d+)/;

    my $id = $1;

    WebService::Pixiv::Illust->new(
	mech => $self->mech,
	id   => $id,
    );
}

1;
