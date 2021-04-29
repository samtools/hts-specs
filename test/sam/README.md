SAM format validation files
===========================

Note, some issues will be checked in multiple categories, eg pos
outside of sequence length and seq-length length / cigar matching.
Also the interplay of undefined fields (CIGAR with pos 0), etc.

We could unify these and declare one such test as the canonical one,
but for now working on each column in turn and investigating all
possibilities has naturally lead to a small amount of duplication.

Other things to consider - floating point values in integers?  Eg pos
10.5,  MAPQ 1e2?  Probably comes under the warning category?


Header
======

Check all acceptable fields can be read, matching their regexp and
required values are indeed required.
Check for duplicates.
General regexp of [A-Za-z][A-Za-z0-9]:[ -~]+ for all bar @CO.
Permitted to freely add new tag:value, but not new line types.

HD
--

Must be first line if present and only occur once

- VN*
  - Must be present, but can be anywhere on line
- SO
  - unknown, unsorted, queryname, coordinate only
- GO
  - none, query, reference
- SS
  - (coordinate|queryname|unsorted)(:[A-za-z0-9_-]+)+

SQ
--

- SN*
  - Must be present.  No dups.  Match regexp
- LN*
  - Must be present and > 0.
- AH
  - chr:start-end, chr or *
- AN
  - Comma separated list.
  - Distinct from SN names or other AN names.
- AS
  - Assembly identifier; no limits listed.
- DS
  - Description.  Explicitly permits UTF8
- M5
  - Lowercase hex symbols only.  Correct length.
- SP
  - Species; no limits listed
- TP
  - linear, circular
- UR
  - URI;  proto:path or path

RG
--

- ID*
  - Must be uniq; no char limits listed
- BC
  - Barcode SEQ or SEQ-SEQ
- CN
  - Centre name; no char limits listed
- DS
  - Description, may contain UTF8
- DT
  - ISO 8601 format date or date/time
- FO
  - Flow order; IUPAC codes or *
- KS
  - key sequence; array of nucleotide bases?
- LB
  - Library; no limits listed
- PG
  - Programs used.  Should it match an @PG line?
    Note it's plural - so end of PG chain?  Comma separated list?
- PI
  - Median insert size; no limit on format.
    *Assume* it's numeric, but maybe float?
    Also assume it's one value - "median" - and not a range.
- PL
  - Platform; CAPILLARY, DNBSEQ, HELICOS, ILLUMINA, IONTORRENT, LS454,
    ONT, PACBIO
- PM
  - Platform model.  May exist when PL is absent (unknown)
- PU
  - Platform unit.  
- SM
  - Sample

PG
--

- ID
  - unique ID
  - Mandatory
- PN
  - name
- CL
  - command line; may use utf8
- PP
  - Previous PG.  ID must match
- DS
  - Description; may use utf8
- VN
  - Program version

CO
--

Free text, doesn't have to honour TAG:VALUE syntax



Data Columns
============

- QName
- Flag
- RName
- Pos
- Map Qual
- CIGAR
- Mate RName
- Mate Pos
- TLEN
- Seq
- Qual
- Aux

General failures:
  - Zero length (empty column) rather than "*" or 0.
  - Not enough columns

Qname
-----

- "*" (missing)
- "*x" (starting with *)
- allowed symbols [!-?A-~]; ie all printable bar @.
- Length; up to 254

- Fails
  - Longer than 254
  - Starting with @ part way through a file
  - Containing disallowed symbols; @ in middle of name

Flag
----

- Single but split into multiple supp and/or secondaries
- Neither READ1/2 set with paired seq (unknown)
- Both READ1/2 set with paired seq (triplet)
- Assumption checking (should pass)
  - Bit x4 (unmapped) but with CIGAR (permit) and MAPQ (permit)
  - Bit x1 unset in conjunction with bit x2, x8, x20, x40, x80.

- Inconsistent values (may not be able to validate, may warn)
  - mate mismatches
    - paired but no flag
    - reversed but no flag
  - multiple primaries
- Fails
  - higher bits used
  - negative values
  - non-numeric
  - possible octal misunderstanding (Leading zeros permitted?)


Rname
-----

- "*"
- Full range of chars.
- Long lines (doesn't have the 254 limit that QNAME does)

- Fails
  - starting * or =
  - invalid chars elsewhere (blackslash, comma, single / double
    quotes, square / curly / angle brackets.
  - doesn't match a known @SQ header line

Pos
---

- Range: 0 to 2^31-1
  - 0 for unmapped
  - >= 1 for mapped
- May be unsorted

- Warn / semantics
  - Syntactically correct, but longer than @SQ line
  - pos 0 with RNAME or CIGAR; "no assumptions can be made".

- Fails
  - out of range
  - non-numeric (eg "*")
  - leading zeros to trip up octal assumptions (099)

Map Qual
--------

- Range: 0 to 255

- Fails
  - out of range
  - non-numeric (eg "*")
  - leading zeros to trip up octal assumptions (099)


CIGAR
-----

- Valid codes
  - M	  match / mismatch
  - = X	  explicit match / mismatch
  - I D	  indels
  - S H	  clips
  - N 	  ref skips
  - P	  padding
  - *	  no CIGAR (both mapped, and unmapped)
- Minimal lengths; zero permitted by regexp
- CIGAR with no sequence shown
- Neighbourng indels; ID and DI
- Reads entirely consisting of insertions (no bases on ref)
  - At pos 1; every base is prior to start of ref
- Neighbouring matching ops, eg 1D1D, 10M10M
- (Cicular genomes?  needs more work.)
- Very large CIGAR strings (BAM has a 64K limit so tools that parse
  SAM into in-memory BAM may fail).

- Warn
  - CIGAR aligning off end of references
  - Zero length seqs? Eg entirely deletions?

- Fails
  - CIGAR length mismatching sequence
    - too short
    - too long
  - Location of H (outer most only)
  - Location of S (outermost bar H)


RNEXT: Mate RName
-----------------

- As per RNAME
- "="
- "*"
- valid chars
- length
- other end not present (subset of file)

- Fail
  - Illegal chars (eg space)
  - Quotes
  - Brackets
  - Missing from header


PNEXT: Mate Pos
--------------

- Simple working case
- Range of values, from 1 to end (if single base long seq)
- 0 for unknown (RNEXT *)
- 0 for not-paired

- May warn
  - Mate name known, but zero location listed ("no assumption")
  - Mate pos doesn't match actual mate pos
  - Mate pos is outside of reference length
  - 0 and flag 0x20 assumptions?
  - Mate data specified on unpaired data

- Paired with secondaries (strict)
  1. Segment is a run of bases.
  2. Read is 1 or more segments
  3. Linear alignment is a read aligned in one record.
  4. Chimeric alignment is a read aligned in multiple records (with suppl).
  5. Only one line per read with FLAG&0x900==0: the "primary line".
     NB: FLAG 0x20 is "next segment"; not next primary record.
  6. RNEXT/PNEXT is defined to be next primary record.
  7. TLEN is defined in segments and not limited to primary.
     TLEN is zero if not all segments map to the same reference.
  The consequence of 7 is that secondary alignments can change the
  primary TLEN field, or even zero it.
  *Assumption*: This is an error in the spec and will be amended.
  Possibly FLAG 0x20 needs to be next primary segment too?

- Warn: Alternative secondary pair encoding which breaks primary
  definition.  RNEXT/PNEXT/TLEN per mapped copy, so secondary
  alignments of a consistent pair will have their own self-consistent
  RNEXT/PNEXT/TLEN figures.

- Warn: Paired with secondaries+supplementaries
  As above.

- Triplets
  - READ1, READ1+READ2 (middle), READ3.
  - (Warn) +Secondary alignments
  - (Warn) +Supplementary alignments


- Fail
  - Negative values
  - Not integer

TLEN
----

- Simple correct values
- Unknown 0
- Actually 0 (needs 5' to 3' interpretation)

- May warn
  - Technically incorrect values
    - +/- 1
    - left/right and not 5' to 3'
  - Woefully wrong values
  - Outside of range of chromosome

- Fail
  - Not integer

Seq
---

- Simple case
- Legal chars (=ACMGRSVTWYHKDBN)
- Empty string ("*")
- Unmapped sequences without any SAM header

- May warn
  - Lowecase (no assumptions may be made, but can't encode case in BAM).
  - U (legal, but not in BAM)
  - Non IUPAC (spec says all of a-zA-Z is legal, but can't put in BAM)

- Fail
  - Illegal chars, including *, . and - in seq.

Qual
----

- Range of values: ! to ~
- ** (meaning two bases of qual 9)
- * for unknown qual, with seq
- * for unknown qual, without seq
- * with length 1 (ambiguity in spec, but must be accepted)

- Fail
  - Different length to sequence
  - Out of legal values; eg space
  - Non * with seq = *

Aux
---

- Tags
  - Range [A-Za-z][A-Za-z0-9]
  - Stress test number of individual tags and length
- Types
  - A [!-~]
    - Full range
    - Fail: outside range, note no space
    - Fail: length != 1
  - i [+-]?[0-9]+
   - explicit +
    - leading zeros
    - range -2^31 to 2^32-1
  - f
    - full range tests
    - explicit +
    - exponentials
    - integers as floats
    - Fail: "10." (not permitted by regexp, but parsed OK by most libs)?
    - Fail: nan (not in regexp)
    - Fail: +/- inf (not in regexp)
  - Z [ !-~]
    - Empty string permitted
    - Length check (>256)
    - Full range
    - Fail: outside range
  - H
    - paired, uppercase
    - empty
    - Fail: odd number / lowercase
  - B
    - test all the sub-fields for size boundaries.
    - Fail: size fields and one past each boundary
    - Fail: other B types

- Fail
  - General syntax
  - Other types (including case change variants of above; I, z, etc)
  - Aux tag not 2 chars
  - Aux tag occuring multiple times


Todo
----

- SAMtags: should have its own directory of tests dedicated to those
  tags.  Eg see the base modifications ones.

  This doc is for tag *format* in SAM rather than specific semantics.  

  However things to consider there.
  - MD / NM consistency
  - RG tag matching header
  - PG tag matching header

