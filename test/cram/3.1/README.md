This directory contains a set of test files in the CRAM 3.1 format.

As CRAM 3.1 is identical to CRAM 3.0 except the version number and
choice of codecs available, this directory does not contain a large
number of files.  It is recommended that CRAM 3.1 implementations
first validate themselves against the CRAM 3.0 data sets, along with
validating the specific codecs in isolation.

Once those two checks have been performed, the files here act as an
integration test for the full CRAM 3.1 specification.

The 4 CRAM files use successive levels of compression codecs in
use.  These are purely representative of choices that could be made in
trading encode time, decode time, granularity of random access and
file size.  They are not prescriptive or a requirement for any encoder
to follow and are intended as examples only.

There are analogous CRAM v3.0 files in cram/3.0/passed/level-[124].cram
and BAM at various gzip levels in bam/passed/level-[19].bam.
All of these files have identical content, with just the encoding
methods differing.

The `samtools cram-size -v` tool can be used for reporting the codecs
used within each CRAM file.

### level-1.cram

Deflate (gzip) level 1, rANS Nx16 order-0 and order-1 only.  The slice
size here is also small.  Some small data blocks are uncompressed.
An example file designed for fine-grained random access and fast decoding.

### level-2.cram

As level-1, but with higher levels of Deflate compression, adds use of
the name tokeniser, and extra data transforms used in the rANS Nx16
codec.  The number of sequences per slice is higher too, offering
a more balanced size versus random access granularity.

### level-3.cram

Uses bzip2 and fqzcomp in addition to the above.  Also uses a
larger container / slice size.  This is more appropriate for long-term
archival purposes.

### level-4.cram

Maximum compression with LZMA and the range-coder in use, plus more
aggressive compression of previous codecs.
