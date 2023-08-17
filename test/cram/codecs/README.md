CRAM codecs test files
======================

The data here corresponds to the new compression codecs implemented in
CRAM 3.0 and 3.1.  Rather than entire CRAM files, these tests
represent individual files compressed using a CRAM codec, with none of
the CRAM blocks, slices or container wrappings present.

Each directory corresponds to a codec, with both the CRAM compressed
file and a corresponding gzip compressed version of the same file.
The CRAM encoded version may have multiple variants, demonstrating
different capabilities of that codec.  For example the CRAM 3.0 rANS
may have an order-0 and order-1 encoding, while the CRAM 3.1 rANS adds
additional bit-packing and RLE methods.

To validate decoder implementations with these files, you should
attempt to decode the CRAM codec-compressed file and demonstrate
identity with the original ungzipped copy after file specific
processing (see below).

To validate an encoder, you can perform a round-trip using each
specific codec option.  While this is not a guarantee of accuracy of
implementation, if the round-trip works while the decoder on the
supplied data also works, then it is a demonstration of correct data
layout.  Note it may not be possible to simply compare compression
outputs as two implementations may choose different frequency tables
where rounding is required.  Both are valid, but different.

Note the origin of these files is the htscodecs self test directory.

    https://github.com/samtools/htscodecs/


Processing
----------

In CRAM the quality values are just encoded together into a single
block with no separators, such as newlines.  The rANS codec just
compresses as-is, while the fqzcomp codec may utilise the sequence
length in order to improve compression.  The name tokeniser doesn't
care what the separator is, but if BYTE_ARRAY_STOP has been used in
CRAM then they could be newline, nul or tab terminated.

For ease of performing round-trip tests, all the data files here are
textual and newline separated (with the exception of the 32-bit
unsigned integer file "u32").

Therefore some transformations are required when performing equality
checks.

As an example, we will use htscodecs' tests.

    $ gzip -cd gzip/q40+dir.gz | perl -ae 'print $F[0]' | md5sum  
    ea2e88c7a117c3989203f6987058d548  -

    $ rans4x16pr -d -r ransNx16/q40+dir.1 | md5sum
    ea2e88c7a117c3989203f6987058d548  -

    $ fqzcomp_qual -d -r fqzcomp/q40+dir.3 | tr -d '\012' | md5sum
    ea2e88c7a117c3989203f6987058d548  -

The perl command outputs the first column in the uncompressed test
data, without newlines.  (The htscodecs fqzcomp_qual program does
however output newlines, so we are removing these for consistency,
but this is specific to the htscodecs implementation of that test tool.)

    $ gzip -cd gzip/10.names | md5sum
    3a45331216b626bce255d12e83a615f3  -

    $ tokenise_name3 -d -r < tok3/10.names.9 | tr '\000' '\012' | md5sum
    3a45331216b626bce255d12e83a615f3  -

Similarly for the name tokeniser, the htscodecs test tool is
using nul bytes, so we transform these to newlines before comparing.

The important thing here is to compare the contents of the files
rather than the specific layout.  Whatever processing you do will be
implementation tool specific.


Specific test data sets
-----------------------

The gzip subdirectory has the original data with names below.

### q4

Fixed length Illumina quality values binned to 4 discrete values.
Good for evaluating the PACK format of rANS-Nx16 and range.

### q8

Fixed length Illumina quality values binned to 8 discrete values.
Good for evaluating the PACK format of rANS-Nx16 and range.

### q40+dir

Fixed length Unbinned Illumina quality values with 40 discrete values.
This file has a second field indicating the strand, 0 for original and
1 for reversed.  This ancillary information could be used by fqzcomp
as a selector bit to improve compression ratios.

Note only the first column will be decoded when using the pre-made
CRAM codec compressed files (although this second column may be
embedded in some of the fqzcomp encodings).

### qvar

Long read quality values with variable length records and many
discrete quality values.

### *.names

Multiple sets of read names produced by a variety of platforms and in
a variety of orders, including single and paired data and both name
sorted and position sorted (which essentially randomises names, but
may have pairings close by).

Note some of the name files are in FASTQ format with `@name` and
potentially ending on /1 or /2.  These won't be the format used
internally with CRAM, but are still designed as a test for coping with
arbitrary name formatting.

The "rr.names" file contains a merge of two different name styles and
may be a useful test for optimising the selection of the previous name
to delta against for a name tokeniser encoder.

### u32

This is a binary file with 32-bit little endian integers.  It is a
useful test of the STRIPE data interleaving capability of the rANS-Nx16
and range codecs.

Note this file is not line-wrapped and should be compared as-is.


Notes on specific codec files
=============================

The fqzcomp, range, rans4x8, ransNx16 and tok3 directories have the
CRAM codec compressed copies of the above files.  There will be
multiple versions of each file with a suffix indicating the encoding
used, as below.

### rans4x8

".0" and ".1" used for Order-0 and Order-1 entropy encoding
respectively.

### ransNx16

The "Order" byte is extended to contain additional bits, with +8 for
STRIPE, +64 for RLE and +128 for PACK.  The suffixes are the decimal
version of these combinations, so ".192" for example is PACK + RLE +
order-0.

### range

As per ransNx16, encoding Order, STRIPE, RLE and PACK.

### fqzcomp

Fqzcomp is different to the range and rans codecs in that it doesn't
have a fixed set of data transformations.  Instead it has an internal
description of various operations and their positions, bit-sizes and
shifts.  We don't describe the precise configuration, and instead have
".0" to ".3" for 4 arbitrary configuration settings.

### tok3

".1" to ".9" can be viewed as a compression level, like gzip -1 to
gzip -9, with more exploration of different compression techniques.
All of these use the rANS-Nx16 entropy encoder.

".11" to ".19" are similar, but using the range coder instead.
