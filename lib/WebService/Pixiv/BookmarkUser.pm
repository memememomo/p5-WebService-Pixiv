package WebService::Pixiv::BookmarkUser;
use strict;
use warnings;
use base qw(WebService::Pixiv::Base);
use URI;
use Web::Scraper;


sub base_uri {
    return 'http://www.pixiv.net/bookmark.php?type=user';
}

sub pager {
    return 50;
}

sub selector {
    my $selector_count = qq|div.two_column_space > h3 > span|;
    my $selector_user_id = qq|li.list_person > a|;

    scraper {
	process $selector_count, count => 'TEXT',
	process $selector_user_id, 'user_id[]' => '@href',
    };
}

sub response {
    my ($self, $res, $item_num) = @_;

    my $href = $res->{user_id}->[$item_num];
    $href =~ /id=(\d+)/;

    return $1;
}

1;
