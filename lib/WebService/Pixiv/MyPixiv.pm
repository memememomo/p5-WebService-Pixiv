package WebService::Pixiv::MyPixiv;
use strict;
use warnings;
use base qw(WebService::Pixiv::Base);
use Web::Scraper;
use WebService::Pixiv::Illust;


sub base_uri {
    my $self = shift;
    return 'http://www.pixiv.net/mypixiv_all.php?id='.$self->id;
}

sub pager {
    return 20;
}

sub selector {
    my $self = shift;

    my ($selector_count, $selector_mypixiv_id);

    if ($self->id == $self->my_user_id) {
	$selector_count = qq|div.two_column_top3 > h3 > span|;
    } else {
	$selector_count = qq|div.two_column_space > h3 > span|;
    }

    $selector_mypixiv_id = qq|li.list_person > a|;

    scraper {
	process $selector_count, count => 'TEXT',
	process $selector_mypixiv_id, 'mypixiv_id[]' => '@href',
    };
}

sub response {
    my ($self, $res, $item_num) = @_;

    my $href = $res->{mypixiv_id}->[$item_num];
    $href =~ /member.php\?id=(\d+)/;

    my $id = $1;
    return $id;
}

1;
