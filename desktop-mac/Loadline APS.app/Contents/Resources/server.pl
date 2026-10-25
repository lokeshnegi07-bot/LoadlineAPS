#!/usr/bin/perl
# Loadline APS local web server: serves the site folder at http://localhost:<port>/ for this Mac only.
use strict; use warnings; use IO::Socket::INET;
my ($root, $port) = @ARGV; $port ||= 8765; $root =~ s{/+$}{};
$SIG{PIPE} = 'IGNORE'; $SIG{CHLD} = 'IGNORE';
my %T = (html => 'text/html; charset=utf-8', js => 'text/javascript; charset=utf-8', css => 'text/css; charset=utf-8', json => 'application/json',
  svg => 'image/svg+xml', png => 'image/png', jpg => 'image/jpeg', jpeg => 'image/jpeg', webp => 'image/webp', ico => 'image/x-icon',
  mp4 => 'video/mp4', webm => 'video/webm', vtt => 'text/vtt', txt => 'text/plain; charset=utf-8');
my $srv = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => $port, Listen => 20, ReuseAddr => 1, Proto => 'tcp') or die "Can't listen on port $port: $!\n";
my $parent = $$;
while (1) {
  my $c = $srv->accept or next;
  my $pid = fork;
  if (!defined $pid || $pid) { close $c; next }
  # child: one request per connection
  close $srv; binmode $c; $c->autoflush(1);
  my $reply = sub { my ($code, $type, $body) = @_; my %st = (200 => 'OK', 204 => 'No Content', 404 => 'Not Found');
    print $c "HTTP/1.1 $code $st{$code}\r\nContent-Type: $type\r\nContent-Length: " . length($body) . "\r\nConnection: close\r\n\r\n$body"; };
  my $req = <$c>; my $path = defined $req && $req =~ m{^\w+\s+(\S+)} ? $1 : '/';
  while (my $h = <$c>) { last if $h =~ /^\r?\n$/ }
  $path =~ s/\?.*//; $path =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
  if ($path eq '/__ping') { $reply->(200, 'text/plain', 'loadline'); exit 0 }
  if ($path eq '/__stop') { $reply->(204, 'text/plain', ''); kill 'TERM', $parent; exit 0 }
  $path .= 'index.html' if $path =~ m{/$};
  my $f = $root . $path;
  if ($path =~ /\.\./ || !-f $f) { $reply->(404, 'text/plain', 'Not found'); exit 0 }
  my ($ext) = $f =~ /\.(\w+)$/; my $type = $T{lc($ext // '')} // 'application/octet-stream';
  open my $fh, '<:raw', $f or do { $reply->(404, 'text/plain', 'Not found'); exit 0 };
  print $c "HTTP/1.1 200 OK\r\nContent-Type: $type\r\nContent-Length: " . (-s $f) . "\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n";
  my $buf; while (read($fh, $buf, 65536)) { print $c $buf or last }
  close $fh; close $c; exit 0;
}
