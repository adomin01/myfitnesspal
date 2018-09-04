#!/usr/bin/env perl

use JSON;
use Data::Dumper;
use Mojolicious::Lite;

my $JSON_FILE = $ENV{'HOME'} . '/simulation_problem.json';

sub remove_old_entries(\%$) {
	my ($hash_ref, $requestor) = @_;
	my %dirty = %{$hash_ref};
	my %clean = ();
	my $now = time();
	while(my ($then, $value) = each(%dirty)) {
		if ( ($then =~ /^\d{10}$/) and ($requestor ne 'admin') ) {
			my $timeout = $dirty{$then}{'timeout'};
			next unless ( ($now - $then) < $timeout );
		}
		$clean{$then} = $value;
	}
	return(%clean);
}

sub get_userdata($$$) {
	my ($file, $username, $requestor) = @_;
	open(my $fh, '<', $file) or die "Cannot open '$file' for read: $!";
	my $json_text = '';
	while(my $line = <$fh>) {
		chomp($line);
		next unless $line;
		$json_text .= $line . "\n";
	}
	close($fh);
	my $reference = decode_json($json_text);
	my %matrix = %{$reference};
	my %dirty_data = %{$matrix{$username}};
	my %clean_data = remove_old_entries(%dirty_data, $requestor);
	return(%clean_data);
}

sub get_username($$) {
	my ($file, $userid) = @_;
	open(my $fh, '<', $file) or die "Cannot open '$file' for read: $!";
	my $json_text = '';
	while(my $line = <$fh>) {
		chomp($line);
		next unless $line;
		$json_text .= $line . "\n";
	}
	close($fh);
	my $reference = decode_json($json_text);
	my %matrix = %{$reference};
	my @usernames = keys(%matrix);
	my $username = '';
	foreach my $name (@usernames) {
		my $id = $matrix{$name}{'id'};
		if ($id == $userid) {
			$username = $name;
			last;
		}
	}
	return($username);
}

sub write_messages(\%$) {
	my ($hash_ref, $json_file) = @_;
	my $json_text = '';
	open(my $wh, '>', $json_file) or die "Cannot open '$json_file' for write: $!";
	print {$wh} to_json( $hash_ref, { ascii => 1, pretty => 1 } );
	close($wh);
}

sub get_newid(\%) {
	my $hash_ref = shift();
	my %data = %{$hash_ref};
	my @usernames = keys(%data);
	my @userids = ();
	foreach my $username (@usernames) {
		my $id = $data{$username}{'id'};
		push(@userids, $id);
	}
	my $newid = 0;
	for (my $ix=1; $ix < 100; $ix++) {
		if (! grep(/^$ix$/, @userids)) {
			$newid = $ix;
			last;
		}
	}
	return($newid);
}

sub get_newhash(\%$$$$) {
	my ($hash_ref, $username, $text, $timeout, $id) = @_;
	my %data = %{$hash_ref};
	my $now = time();
	$data{$username}{'id'} = $id;
	$data{$username}{$now}{'text'} = $text;
	$data{$username}{$now}{'timeout'} = $timeout;
	return(%data);
}

sub get_matrix($) {
	my ($file) = @_;
	open(my $fh, '<', $file) or die "Cannot open '$file' for read: $!";
	my $json_text = '';
	while(my $line = <$fh>) {
		chomp($line);
		next unless $line;
		$json_text .= $line . "\n";
	}
	close($fh);
	my $reference = decode_json($json_text);
	my %matrix = %{$reference};
	return(%matrix);
}

sub get_userid(\%$) {
	my ($hash_ref, $username) = @_;
	my %matrix = %{$hash_ref};
	my $id = $matrix{$username}{'id'};
	return($id);
}

sub get_display(\%) {
	my $hash_ref = shift();
	my %ugly = %{$hash_ref};
	my %pretty = ();
	while(my ($epoch, $textinfo_ref) = each(%ugly)) {
		if ($epoch =~ /^\d{10}$/) {
			my %textinfo = %{$textinfo_ref};
			my $timeout = $textinfo{'timeout'};
			my $text = $textinfo{'text'};
			my $expiration_date = localtime($epoch + $timeout);
			$pretty{$epoch}{'expiration_date'} = $expiration_date;
			$pretty{$epoch}{'text'} = $text;
		} else {
			$pretty{$epoch} = $textinfo_ref;
		}
	}
	return(%pretty);
}

## Main

get '/chat/:id' => sub {
	my $c   = shift;
	my $id = $c->param('id');
	my $username = get_username($JSON_FILE, $id);
	my %user_texts = get_userdata($JSON_FILE, $username, 'admin');
	my %display_texts = get_display(%user_texts);
	$c->render(text => '<PRE>' . to_json( \%display_texts, { ascii => 1, pretty => 1 } ) . '</PRE>' . "\n");
};

get '/chats/:username' => sub {
	my $c   = shift;
	my $username = $c->param('username');
	my %user_texts = get_userdata($JSON_FILE, $username, $username);
	my %display_texts = get_display(%user_texts);
	$c->render(text => '<PRE>' . to_json( \%display_texts, { ascii => 1, pretty => 1 } ) . '</PRE>' . "\n");
};

post '/chat' => sub {
	my $c   = shift;
	my $username = $c->param('username');
	my $text = $c->param('text');
	my $timeout = $c->param('timeout');
	my %matrix = get_matrix($JSON_FILE);
	my $userid = 0;
	if (exists($matrix{$username})) {
		$userid = get_userid(%matrix, $username);
	} else {
		$userid = get_newid(%matrix);
	}
	my %newhash = get_newhash(%matrix, $username, $text, $timeout, $userid);
	write_messages(%newhash, $JSON_FILE);
	$c->render(text => to_json( { id => $userid }, { ascii => 1, pretty => 1 } ) . "\n");
};

app->start;
