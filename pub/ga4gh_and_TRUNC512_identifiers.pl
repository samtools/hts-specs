#!/usr/bin/env perl

use strict;
use warnings;

# Both modules must be installed
use Digest::SHA qw/sha512_hex sha512/;
use MIME::Base64 qw/encode_base64url decode_base64url/;

sub ga4gh_digest {
  my ($sequence, $digest_size) = @_;
  $digest_size //= 24;
  if(($digest_size % 3) != 0) {
    die "Digest size must be a multiple of 3 to avoid padded digests";
  }
  my $digest = sha512($sequence);
  return _ga4gh_bytes($digest, $digest_size);
}

sub trunc512_digest {
  my ($sequence, $digest_size) = @_;
  $digest_size //= 24;
  my $digest = sha512_hex($sequence);
  my $substring = substr($digest, 0, $digest_size*2);
  return $substring;
}

sub _ga4gh_bytes {
  my ($bytes, $digest_size) = @_;
  my $base64 = encode_base64url($bytes);
  my $substr_offset = int($digest_size/3)*4;
  my $ga4gh = substr($base64, 0, $substr_offset);
  return "ga4gh:SQ.${ga4gh}";
}

sub ga4gh_to_trunc512 {
  my ($ga4gh) = @_;
  my ($base64) = $ga4gh =~ /ga4gh:SQ.(.+)/;
  my $digest = unpack("H*", decode_base64url($base64));
  return $digest;
}

sub trunc512_to_ga4gh {
  my ($trunc_digest) = @_;
  my $digest_length = length($trunc_digest)/2;
  my $digest = pack("H*", $trunc_digest);
  return _ga4gh_bytes($digest, $digest_length);
}

print 'GA4GH identifier: ', ga4gh_digest('ACGT'), "\n";
# ga4gh:SQ.aKF498dAxcJAqme6QYQ7EZ07-fiw8Kw2

print 'TRUNC512: ', trunc512_digest('ACGT'), "\n";
# 68a178f7c740c5c240aa67ba41843b119d3bf9f8b0f0ac36

print "\n";

print 'Convert TRUNC512 to GA4GH ', trunc512_to_ga4gh(trunc512_digest('ACGT')), "\n";
# ga4gh:SQ.aKF498dAxcJAqme6QYQ7EZ07-fiw8Kw2

print 'Convert from GA4GH to TRUNC512 ', ga4gh_to_trunc512(ga4gh_digest('ACGT')), "\n";
# 68a178f7c740c5c240aa67ba41843b119d3bf9f8b0f0ac36

print "\n";

print 'Digest of an empty sequence ', ga4gh_digest(''), "\n";
# ga4gh:SQ.z4PhNX7vuL3xVChQ1m2AB9Yg5AULVxXc
