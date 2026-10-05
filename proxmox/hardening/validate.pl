#!/usr/bin/perl
# Compile candidate files in memory using the installed PVE version; never apply.
use strict;
use warnings;
use PVE::Cluster;
use PVE::INotify;
use PVE::Firewall;
use PVE::FirewallSimulator;

my $dir = shift // die "usage: validate.pl CANDIDATE_DIRECTORY\n";
-d $dir or die "missing candidate directory\n";
-f "$dir/cluster.fw" && -f "$dir/host.fw" or die "missing candidate files\n";
PVE::Cluster::cfs_update();
PVE::Firewall::set_verbose(1);
local $SIG{__WARN__} = sub { die "Firewall validation warning: @_" };
my $cluster = PVE::Firewall::load_clusterfw_conf("$dir/cluster.fw");
my $host = PVE::Firewall::load_hostfw_conf($cluster, "$dir/host.fw");
my ($v4, $sets, $v6) = PVE::Firewall::compile($cluster, $host);
my $host_ip = PVE::Cluster::remote_node_ip(PVE::INotify::nodename());
my $vmdata = PVE::Firewall::read_local_vm_config();
my @tests;
for my $port (22, 8006, 3128, 5900, 5999, 60000, 60050, 111, 44321, 45876) {
    push @tests, ["LAN blocked $port", '192.168.1.201', $port, 'DROP', 'tcp', 'outside', 4];
    push @tests, ["guest blocked $port", '192.168.40.105', $port, 'DROP', 'tcp', 'outside', 4];
    push @tests, ["IPv6 LAN blocked $port", 'fe80::1234', $port, 'DROP', 'tcp', 'outside', 6];
}
for my $source ('192.168.1.1', '192.168.1.3') {
    for my $pair ([22, 'tcp'], [8006, 'tcp'], [60000, 'tcp'], [60050, 'tcp'],
                  [5405, 'udp'], [5412, 'udp'], [4789, 'udp'], [179, 'tcp']) {
        push @tests, ["cluster $source @$pair", $source, $pair->[0], 'ACCEPT', $pair->[1], 'outside', 4];
    }
}
for my $source ('192.168.1.205', '192.168.1.253') {
    for my $port (22, 8006) {
        push @tests, ["controller $source $port", $source, $port, 'ACCEPT', 'tcp', 'outside', 4];
    }
    push @tests, ["controller non-admin service denied", $source, 111, 'DROP', 'tcp', 'outside', 4];
}
for my $port (22, 8006, 3128, 5900, 5999) {
    push @tests, ["tailnet IPv4 $port", '100.103.53.34', $port, 'ACCEPT', 'tcp', 'tailscale0/eth0', 4];
    push @tests, ["tailnet IPv6 $port", 'fd7a:115c:a1e0::2a37:3522', $port, 'ACCEPT', 'tcp', 'tailscale0/eth0', 6];
}
push @tests,
    ['Beszel IPv4', '100.117.177.66', 45876, 'ACCEPT', 'tcp', 'tailscale0/eth0', 4],
    ['Beszel IPv6', 'fd7a:115c:a1e0::b401:b142', 45876, 'ACCEPT', 'tcp', 'tailscale0/eth0', 6],
    ['Tailscale UDP', '198.51.100.10', 41641, 'ACCEPT', 'udp', 'outside', 4],
    ['Tailscale UDP IPv6', '2001:db8::10', 41641, 'ACCEPT', 'udp', 'outside', 6];
for my $test (@tests) {
    my ($name, $source, $port, $want, $proto, $from, $version) = @$test;
    my $rules = $version == 4 ? $v4 : $v6;
    my $ip = $version == 4 ? $host_ip : 'fe80::1';
    my $got = PVE::FirewallSimulator::simulate_firewall(
        $rules->{filter}, $sets, $ip, $vmdata,
        { from => $from, to => 'host', source => $source, dest => $ip,
          proto => $proto, sport => 45000, dport => $port, action => 'QUERY' });
    die "$name: expected $want, got $got\n" unless $got eq $want;
}
printf "PASS: native PVE compilation and %d packet simulations on %s\n", scalar(@tests), PVE::INotify::nodename();
print "Covers candidate PVE rules only, not Tailscale's separate kernel chains or live routing.\n";
