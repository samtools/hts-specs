Main concepts
-------------

Try to test in order, so early tests don't require correct
interpretation of later tests.  This gives an ordering for software
development and testing.

- Data types
  - ITF8
  - Strings
  - Arrays
  - Maps

- File definition (magic number)
  - Blocks
- SAM header
- Container basics
- Compression header
- Slices
  - Unmapped
  - Mapped, no reference
  - Mapped, external reference
  - Embedded reference
- Tags
  - Basic types
  - Auto-generated tags (RG, MD, NM)
- Advanced containers
  - Multi-slice
  - Multi-ref
- Built-in compression types
- Lossy compression
  - Read names
  - Quality
- Data layout
  - CORE block; HUFFMAN, BETA
- Corner cases
- Slice tags
  - Optional auxiliary tags after slice header


Do we need lower level tests of components.  Eg ITF8 format data, not
as part of a CRAM file itself?  (We do this for the codecs already in
htscodecs repo.)

Most CRAM test files are uncompressed.  It's only when we want to test
the compression codecs that it matters.  This aids debugging with hexdumps.

The specification describes the file format and the decode process.
Hence these files validate CRAM decoder only.  However some may also
be used for testing CRAM encoder by doing round-trips; CRAM (these
files) -> SAM (1) -> CRAM (new) -> SAM (2) and compare the two SAMs.
For encoders it would also be recommended to take the SAM test data
and validate it can round trip in and out of CRAM, as those files
contain a variety of edge cases.

Each CRAM file has an associated SAM file which represents the decoded
data.

Prerequisites
-------------

- Before decoding the first test CRAM file, a CRAM decoder will
  require an implementation of the ITF8 data type, the block
  structure / data type, and CRC32 checking.


File definition (magic number)
------------------------------

An empty file to check the file definition can be read.
We require a SAM header too, but this is also empty (using one
block, see below).

- Empty CRAM file (0000_empty_noref.cram)
  - File definition
  - SAM header container (zero content)
  - [End of file; no EOF block so may emit warning]

  [Produced by manually removing EOF from 0001_empty_eof.cram]

- Empty CRAM file with EOF block (0001_empty_eof.cram)
  - As above, but with official EOF block.

    This EOF block can be decoded either by checking for a specific
    series of bytes, or by decoding it as Container and Compression
    Header Block structures and checking the specific fields for their
    EOF magic-values.

[Subsequent files all have valid EOF block.]


SAM header
----------

A file with no reads, but containing a SAM header.  We have this in
basic form and also with an additional blank block for header growth.

- Sequence records, including M5 tags (0100_header1.cram)

  [ Produced by setting blank_block = 0 and padded_length = 0 in
    io_lib's cram_write_SAM_hdr(). ]

- With optional second block of blanks, to facilitate
  SAM header in-line replacement (0101_header2.cram)

[Subsequent files all use the extra block of blank data for header
extension.]


Container basics
----------------

A file with no reads, but with a compression header detailing the
fundamentals of the container header structure and compression header
block.

[ Encode a single read file, using same header from above, and remove
  slice from container in gdb.

  b cram_flush_container2
  r
  set c->num_bases=0
  set c->num_records=0
  set c->num_landmarks=0
  set c->curr_slice=0
  set c->length=181
  c ]

- Container structure + compression header (0200_cmpr_hdr.cram)
  - Contains Preservation map
    - RN, SM (Substitution map), TD (empty tag definition), AP
  - Record encoding map
    - RL, RN, QS, BA, BB, TL, IN, BF, MF, TS, CF, AP, MQ, NP, SC, NS,
      RG, RI.
    - Uses encodings EXTERNAL, HUFFMAN, BYTE_ARRAY_STOP and
      BYTE_ARRAY_LEN.
  - Tag encoding map (empty)


Slice basics, unmapped
----------------------

Files with 1 or more sequences.  These are all unmapped with no
auxiliary tags.

- Single read (0300_unmapped.cram)
  - Tests decoded data via EXTERNAL, HUFFMAN, BYTE_ARRAY_STOP and
    BYTE_ARRAY_LEN encodings.
  - 4 blocks in slice (CORE - empty, RN, QS, BA).

- Two unpaired reads, of differing length (0301_unmapped_cram)
  - As above, but RL is no longer a constant and is in its own block.

- Three reads, including a pair (0302_unmapped_cram)
  - Also contains BF and MF blocks.  All still CF "detached".
  - BF 77 & 141 match the input SAM, but this is redundant as it's
  - also set in MF bit 2.

- Three reads, including a pair (0303_unmapped_cram)
  - As above, but the SAM FLAGs of 77 and 141 are stored as 69 and 133
    (clearing mate unmapped flag).  BF + MF are sufficient to
    regenerate the correct FLAG field.

  [ Produced with a SAM file using FLAG 77/141 and under gdb
    explicitly doing "set cr->mate_flags=2" before writing it. ]


Slice basics, mapped reads, no reference
----------------------------------------

- Single read (0400_mapped.cram)
  - Container ref id, pos and span, number of records and number of
    bases fields are changed.
  - Checks that mapped data can process MD5 0, provided container RR=0.
  - Additional data series in use: FN, FP, FC, MQ.
  - One feature of type 'b', with sequence stored in BB.

- Paired reads, but detached (0401_mapped.cram)
  - RNEXT/PNEXT/TLEN of */0/0
  - Explicit TS, NP, NS with constant values as they would disagree
    with auto-computed values.

- Paired reads, but detached (0402_mapped.cram)
  - RNEXT/PNEXT/TLEN filled out.
  - Explicit TS, NP, NS, with non-constant values
    [ Edit htslib to force bam_ins_size check to fail and
      hence "goto detached". ]

- Paired reads, mate downstream (0403_mapped.cram)
  - No TS, NP, NS needed, but has NF (next fragment) instead.
  - RNEXT/PNEXT/TLEN should be derived with values identical
    to 0402_mapped.cram


Slice basics, mapped reads, with reference
-------------------------------------------

Testing of the FC (Feature Codes) data series types and their
associated type-specific data series.

- External reference, CIGAR ops (0500_mapped.cram)
  - No edits: entirely match reference
  - No FP/FC needed (and FN=0).
  - Sequence is implicitly assumed to entirely match reference
  - Header gains an @SQ UR: tag, although note this pathname is local
    and not transferable to other systems.

- External reference, CIGAR ops (0501_mapped.cram)
  - Mismatching first and last base on first seq and first / last 3
    bases on second seq.
  - Adds use of FC "X" and the BS (base substitution) data series.
    This tests the compression header "SM" preservation map.
    Note BB data series has an encoding in the compression header, but
    is not used here.

- As above, but R/Y bases (0502_mapped.cram).
  - Test of the BA data series and FC "B" code.
    BS (base substitution) only applies for A, C, G, T, N.

    Note "B" FC code reads both base plus quality.  However if we have
    preserved quality too then this will be overwritten by the QS data
    series.
    
    This test file has different qualities for the first two "B"
    codes, to test this.

    [ Produced by breaking in htslib's cram_compress_slice and modify
      s->block[12]->data[0].]

- As above with R/Y bases, using using "b" FC (0503_mapped.cram).
  - Unlike FC "B", "b" is a string instead of a single character and
    doesn't require storing quality data.

    [ Produced by changing the "if (0 && CRAM_MAJOR_VERS...)" line in
      process_one_read().]

- Soft/hard clips (0504_mapped.cram)
  - FC codes S and H, with associated SC and HC data series.

- Indels (0505_mapped.cram)
  - Tests FC codes and data-series: D (DL), I (IN) and i (BA).
    The table below shows cigar ops, with "m" being lowercase as it's
    not explicitly stored in CRAM. The FC row shows the associated
    CRAM feature code.
    REF ATTTTTCGGGTTTTTTGAAATGAATATCGTAGCTACAGAAACGGTTGTGCACTCATCTGAAAGTTTGTTT     T TCTTGTTTTCTTGCACTTTGTGCAGAATT
    SEQ ATTTTTCGGGTTTTTTGAAA     AT GTAGCTACAGAAACGGTTGTGCACTCATCTGAAAGTTTGTTTGAAAGTATCTTGTTTTCTTGCACTTTGTGCAGAATT
    CIG mmmmmmmmmmmmmmmmmmmmDDDDDmmDmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmIIIIImImmmmmmmmmmmmmmmmmmmmmmmmmmmmm
    FC                      D      D                                          I     i

- As above, but explicit padding in the 5bp indel (0506_mapped.cram)
  - Tests FC code P and data series PD
    REF ATTTTTCGGGTTTTTTGAAATGAATATCGTAGCTACAGAAACGGTTGTGCACTCATCTGAAAGTTTGTTT     T TCTTGTTTTCTTGCACTTTGTGCAGAATT
    SEQ ATTTTTCGGGTTTTTTGAAA     AT GTAGCTACAGAAACGGTTGTGCACTCATCTGAAAGTTTGTTT*AAA*TATCTTGTTTTCTTGCACTTTGTGCAGAATT
    CIG mmmmmmmmmmmmmmmmmmmmDDDDDmmDmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmPIIIPmImmmmmmmmmmmmmmmmmmmmmmmmmmmmm
    FC                      D      D                                          PI  P i

- As above, but with a ref-skip (0507_mapped.cram)
  - Tests FC code N and data series RS
    REF ATTTTTCGGGTTTTTTGAAATGAATATCGTAGCTACAGAAACGGTTGTGCACTCATCTGAAAGTTTGTTT     T TCTTGTTTTCTTGCACTTTGTGCAGAATT
    SEQ ATTTTTCGGGTTTTTTGAAA     AT GTAGCTACAG---------------------AAAGTTTGTTT*AAA*TATCTTGTTTTCTTGCACTTTGTGCAGAATT
    CIG mmmmmmmmmmmmmmmmmmmmDDDDDmmDmmmmmmmmmmNNNNNNNNNNNNNNNNNNNNNmmmmmmmmmmmPIIIPmImmmmmmmmmmmmmmmmmmmmmmmmmmmmm
    FC                      D      D          N                               PI  P i


Embedded reference
------------------

- Alignments against an embedded reference (0600_mapped.cram)
  The first read matches 0507.  The second has additional SNPs to
  validate BS substitution and literal BA edits against the reference.
  [ Same htslib edits as 0503 ]

- As above, but slice reference MD5 is zero (0601_mapped.cram)
  This is not required when preservation header has RR=0.
  [ Same htslib edits as 0503, plus zero md5 ]

- TODO: embedded ref having different MD5 to external ref?


Tags
----

- TD data series; basic (0700_tag.cram)
  One single integer tag.
  Tests TD map, TL data series, and the tag encoding map.

- Blank tag lines (0701_tag.cram)
  As above but one read has no tags.
  TD now has two entries, one of which is blank.

- common tag types: integer, float, string (0702_tag.cram)

- Different integer sizes (0703_tag.cram)
  Like BAM, CRAM has c, C, s, S, i and I encodings.

- A tags (0704_tag.cram)

- H tags (0705_tag.cram)

- B tag types (0706_tag.cram)

- Explicit vs implicit MD and NM (0707_tag.cram)
  These MD/NM match the computed values (eg samtools calmd),
  so normally wouldn't be stored (but forced with e.g.
  "samtools view -O cram,store_md,store_nm").

- Explicit vs implicit MD and NM (0708_tag.cram)
  This data has invalid MD/NM tags.  The decoder should honour
  the specified tags, although may warn.

- Explicit RG (0709_tag.cram)
  RG:Z tag is stored verbatim and the RG data series is -1 (to
  indicate the RG tag should not be auto-generated).

- Implicit RG (0710_tag.cram)
  No RG:Z tag stored verbatim, and the RG data series is used to
  specify which read group to emit.  Both 0709 nd 0710 should decode
  to the same content.
  Note this data is unsorted too so tests preservation map AP=0


Multi-container, Multi-slice, Multi-ref
---------------------------------------
  - Multiple concatenated containers (0800_ctr.cram)

  - Multiple references in the same container (0801_ctr.cram)
    Used for many small references / contigs.
    Same output expected as 0800.

  - Multiple slices per container (0802_ctr.cram)
    3 slices per container, 3 reads per slice.
    Same output expected as 0800.

Built-in compression types
--------------------------

All identical content.  All blocks compressed as specified bar the
CORE block, which may only be compressed with GZIP.

- Uncompressed baseline (0900_comp_raw.cram)
- Gzip         (0901_comp_gz.cram)
- Bzip2        (0902_comp_bz2.cram)
- Lzma         (0903_comp_lzma.cram)
- rANS order 0 (0904_comp_rans0.cram)
- rANS order 1 (0905_comp_rans1.cram)


Lossy modes
-----------

- Lossless read-names baseline (1000_name.cram)
  Also tests RNEXT being another reference (so not = or *).

- Read names absent (1001_name.cram)
  Tests preservation map RN=0.
  Recs r1 and r2 are paired and within the same slice, so the names
  are absent. Those retained are labelled as detached, which still
  forces decode of RN data series.

- Quality absent, unmapped (1002_qual.cram)
  Unmapped data, with 3 out of 4 sequences having no QS fields.
  This also tests the CF data series.
  [ set cr->cram_flags=0 in process_one_read after // Unmapped comment. ]
  Absolutely no quality, so `*` is the suitable qual to decode.

- Quality absent, mapped with diff (1003_qual.cram)
  Using feature code "B" (base + qual).
  Has partial quality, so should decode with a default qual for the
  missing values and #, X, C etc for the supplied quals.

  In this file "match" pair has the CF&1 flag clear, as does "noqual".
  Read "qual" has quality values stored verbatim.  Read "qstar" had
  quality string `*` which is stored verbatim as a string of quality
  255, as it is also encoded in BAM.  "Qstar" and "noqual" are
  expected to decode the same.  The spec has nothing to say about the
  default quality to use for missing qualities in "match", but as the
  entire quality string is not `*` they have to be set to something.

- Quality absent, mapped with diff (1004_qual.cram)
  With explicit Q features to flag specific bases as needing
  their quality retained.
  [ if (1) vs if (fd->no_ref && ...) for BAM_CSOFT_CLIP case in
    process_one_read, along with sam breakpoint to set cr->cram_flags = 0 ]

- Quality absent, mapped with diff (1005_qual.cram)
  As 1004_qual.cram but using 'q' instead of a series of 'Q' features.
  [ complex to generate! see CRAM.q.gen.patch ]

- Sequence `*` (1006_seq.cram)
  Tests CF bit 0x8.
  CIGAR is basic 100M.

- Sequence `*` (1007_seq.cram)
  CIGAR has soft-clips. These have to be stored in the SC data series
  to regenerate the cigar, but the sequence stored does not matter as
  we decode SEQ to `*`.  Hence this is filled out with Ns.
  

Data layout
-----------

- All in CORE block (1100_CORE.cram)
  All data series bar RN, QS and SC are in CORE block.
  Tests that the order of decoding as the data series are now
  interleaved together.

  [ Produced via "scramble -q -r ../ce.fa" with cram_stats.c changed
    to always return E_HUFFMAN. ]

- All in CORE block, BETA (1101_BETA.cram)
  As above but with BETA encoding instead of huffman

Corner cases
------------

- Beyond end of reference (1200_overflow.cram)
  The bit that overlaps the reference matches, with bases
  beyond that being stored explicitly.
  (It is not permissible to have reference matches outside the range
  of the reference.)


Slice tags
----------

There are are no formally described header in the current
specification, but the format of them is specified and user-defined
tags are permitted.  These files are examples produced by some current
implementations.

- Extra aux fields after slice structure: (1300_slice_aux.cram)
  BD:B:c, and SD:B:c, CRC checksums for bases and quality scores.
  [ Produced by Scramble, with a tweak to fd->ignore_chksum ]

- Extra aux fields after slice structure: (1301_slice_aux.cram)
  As above, but more tags (B5, B1, S5, S1).
  [ Produced by Htsjdk ]


Encodings
---------

- EXTERNAL already tested
- HUFFMAN already tests (both minimally for uni-symbol data, but more
  extensively in 1100_HUFFMAN.cram)
- BYTE_ARRAY_LEN already tested
- BYTE_ARRAY_STOP already tested
- BETA (already tested in 1101_BETA.cram)


- SUBEXPONENTIAL
  - I have no code to write this data format.
    Exists in htsjdk though?

- GAMMA
  - I have no code to write this data format.
    Exists in htsjdk though?

- GOLOMB (deprecated)
  - I have no code to read nor write this data format

- GOLOMB-RICE (deprecated)
  - I have no code to read nor write this data format


Index
-----

- Simple mapped case (1400_index_simple.cram)
  - 10bp reads starting one per base.  Read name indicates
    bases covered.
  - 77 reads per container
  - Index query CHROMOSOME_I:333-444 should return 121 records,
    from s324-333 to s444-453

- Unmapped data (1401_index_unmapped.cram)
  - As above, but all data is unmapped
  - Index query for unmapped (eg ref `*`) should return all 1000 records.

- Multiple references + unmapped (1402_index_3ref.cram)
  - 300 for first ref, 10 for second, 300 for third, and 300 unmapped.
  - Only one reference per slice.
  - CHROMOSOME_I:100-200 returns 110 records
  - CHROMOSOME_II:5-5    returns 5 records
  - CHROMOSOME_II:10-10  returns 10 records
  - CHROMOSOME_II:15-15  returns 5 records
  - CHROMOSOME_III:15-15 returns 10 records
  - `*` (unmapped)         returns 300 records

- Multi-ref mode (1403_index_multiref.cram)
  - As above, but containers / slices use the RI data series with
    multiple references per container.
    The same queries will work as above.
  - Hence index reports reference IDs, but multiple references can
    occur at the same location:

    #ID POS     SPAN    Ctr.OFF Slc.OFF SIZE
    0	199	75	2289	202	416
    0	265	45	2931	199	429
    1	1	19	2931	199	429
    2	1	29	2931	199	429
    2	21	75	3583	202	386

    The container at 2931 has the last reads in ref 0 (CHROMOSOME_I),
    all of ref 1, and the first reads in ref 2.  Similarly the
    unmapped data shares the same container as the last reads in ref 2.

- Multi-slice containers (1404_index_multislice.cram)
  - As 1402_index_3ref.cram, but 3 slices per container.
  - Same queries will work as above.

- Multi-slice multi-ref containers (1405_index_multisliceref.cram)
  - As above, but with multiple references permitted per slice.
  - Same queries will work as above.

- Mix of long and short reads
  - 10bp reads starting every position
  - 350bp reads starting every 300 positions

 - Query to CHROMOSOME_I:500-550 should decode these containers,
   returning 61 records:

```
                                      500  550
      1  350   ------------------       |  |
     66  140      ----                  |  |
    132  206         ----               |  |
    198  272            ----            |  |
    264  650                ====================
    329  403                   ----     |  |
    395  469                      ----  |  |
    461  535                          ==== |
    527  601                             ====
    593  950                                ------------------
    658  732                                   ----
    724  798                                       ----
    790  864                                          ----
    856 1250                                             --------------------
    921  995                                                 ----
    987 1009                                                    --
```

 - Query to CHROMOSOME_I:500-650 returns 162 records
 - Query to CHROMOSOME_I:610-910 returns 313 records


Structure fields checklist
--------------------------

Also note that while we validate most things in these tests, we do not
yet have should-fail tests.

Container
  - Fields validated:
    Length, ref seq (-1, -2, >= 0), start, span, num blocks, landmarks, crc
  - Not validated
    Alignment num records, counter, 

Block
  - All fields validated

Preservation map
  - Validated: RN, AP, RR, TD
  - SM used, but all tests have the same map.

Data series
  - Validated: AP, BA, BB, BF, BS, CF, DL, FC, FN, FP, HC, IN, MF, MQ,
    NF, NP, NS, PD, QS, QQ, RG, RI, RL, RN, RS, SC, SQ, TL, TN, TS
  - CF: all 4 bits tested
  - MF: both bits tested

Tag types
  - Validated: C c S s I i f A Z H B

Slice
  - Field validated:
    Ref seq, start, span, MD5, num blocks, blk IDs, embedded ref id
  - Not validated
    Counter, num records, Optional tags

EOF validated

Encodings
  - Validated: External, Huffman, byte array len, byte array stop, beta
  - Not validated: subexponential, gamma, golomb, golomb rice

Compression
  - Validated: none, gzip, bzip2, lzma, rans (order 0, order 1)
