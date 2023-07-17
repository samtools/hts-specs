---
layout: default
title: refget protocol
suppress_footer: true
---

# Refget API Specification v2.0.0
{:.no_toc}

* Do not remove this line (it will not be displayed)
{:toc}

## Introduction

Reference sequences are fundamental to genomic analysis and interpretation however naming is a serious issue. For example the reference genomic sequence GRCh38/1 is also known as hg38/chr1, CM000663.2 and NC_000001.11. In addition there is no standardised way to access reference sequence from providers such as INSDC (ENA, Genbank, DDBJ), Ensembl or UCSC.

Refget enables access to reference sequences using an identifier derived from the sequence itself.

Refget uses a hash algorithm (by default `MD5`) to generate a checksum identifier, which is a digest of the underlying sequence. This removes the need for a single accessioning authority to identify a reference sequence and improves the provenance of sequence used in analysis. In addition refget defines a simple scheme to retrieve reference sequence via this checksum identifier.

Refget is intended to be used in any scenario where full or partial access to reference sequence is required e.g. the CRAM file format or a genome browser.

## Design principles

The API has the following features:

- The checksum algorithm used to derive the sequence identifier shall be a mainstream algorithm available standard across multiple platforms and programming languages.
- The client may request a sub-sequence, which the server is expected to honour
- Refget was designed to enable access to nucleotide sequences, however other sequences could be provided via the same mechanism e.g. cDNA, CDS, mRNA or proteins
- Optionally the API provides a retrieval of the sequence and metadata via a unique identifier

## OpenAPI Description

An OpenAPI description of this specification is available and [describes the 2.0.0 version](pub/refget-openapi.yaml). OpenAPI is a language independent way of describing REST services and is compatible with a number of [third party tools](http://openapi.tools/). (Note: if there are differences between this text and the OpenAPI description, this specification text is definitive.)

## Compliance

Implementors can check if their refget implementations conform to the specification by using our [compliance suite](https://github.com/ga4gh/refget-compliance-suite). A summary of all known public implementations is available from our [compliance report website](https://andrewyatz.github.io/refget-compliance/).

## Protocol essentials

All API invocations are made to a configurable HTTP(S) endpoint, receive URL-encoded query string parameters and HTTP headers, and return text or other allowed formatting as requested by the user. Successful requests result with HTTP status code 200 and have the appropriate text encoding in the response body as defined for each endpoint. The server may provide responses with chunked transfer encoding. The client and server may mutually negotiate HTTP/2 upgrade using the standard mechanism.

The response for sequence retrieval has a character set of US-ASCII and consists solely of the requested sequence or sub-sequence with no line breaks. Other formatting of the response sequence may be allowed by the server, subject to standard negotiation with the client via the Accept header.

Requests adhering to this specification MAY include an Accept header specifying an alternative formatting of the response, if the server allows this. Otherwise the server shall return the default content type specified for the invoked method.

HTTP responses may be compressed using [RFC 2616](https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html) transfer-coding, not content-coding.

HTTP response may include a 3XX response code and Location header redirecting the client to retrieve sequence data from an alternate location as specified by [RFC 7231](https://tools.ietf.org/html/rfc7231), clients SHOULD be configured follow redirects. `302`, `303` and `307` are all valid response codes to use.

Range headers are the preferred method for clients making sub-sequence requests, as specified by [RFC 7233](https://tools.ietf.org/html/rfc7233).

Requests MAY include an Accept header specifying the protocol version they are using:

```
Accept: text/vnd.ga4gh.refget.v2.0.0+plain
```

Responses from the server MUST include a Content-Type header. A plain text (`text/plain`) response MAY include the encoding for the invoked method and protocol version. The refget protocol reserves `text/plain` for the transfer of sequence data. A JSON response MUST include the encoding for the invoked method and protocol version for example:

```
Content-Type: application/vnd.ga4gh.refget.v2.0.0+json; charset=us-ascii
```

## Internet Media Types Handling

When responding to a request a server MUST use the fully specified media type for that endpoint. When determining if a request is well-formed, a server MUST allow a internet type to degrade like so

- `text/vnd.ga4gh.refget.v2.0.0+plain; charset=us-ascii`
  - `text/vnd.ga4gh.refget.v2.0.0+plain`
  - `text/plain`
- `application/vnd.ga4gh.refget.v2.0.0+json; charset=us-ascii`
  - `application/vnd.ga4gh.refget.v2.0.0+json`
  - `application/json`

## Errors
The server MUST respond with an appropriate HTTP status code (4xx or 5xx) when an error condition is detected. In the case of transient server errors (e.g., 503 and other 5xx status codes), the client SHOULD implement appropriate retry logic. For example, if a client sends an alphanumeric string for a parameter that is specified as unsigned integer the server MUST reply with `Bad Request`.

|  Error type             | HTTP status code | Description                                                                                          |
|-------------------------|------------------|------------------------------------------------------------------------------------------------------|
| `Bad Request`           | 400              | Cannot process due to malformed request, the requested parameters do not adhere to the specification |
| `Unauthorized`          | 401              | Authorization provided is invalid                                                                    |
| `Not Found`             | 404              | The resource requested was not found                                                                 |
| `Not Acceptable`        | 406              | The requested formatting is not supported by the server                                              |
| `Conflict`              | 409              | The document requested cannot be uniquely resolved from the provided identifier                      |
| `Range Not Satisfiable` | 416              | The Range request cannot be satisfied                                                                |
| `Not Implemented`       | 501              | The specified request is not supported by the server                                                 |

## Security
Reference sequence as defined in this specification is publicly accessible without restrictions. Adapting the implementation to retrieve private/potentially sensitive genomic data is not a good use of the protocol. In any circumstances, no personal data should be shared without proper data security measures.

Sensitive information transmitted on public networks, such as access tokens and human genomic data, MUST be protected using Transport Level Security (TLS) version 1.2 or later, as specified in [RFC 5246](https://tools.ietf.org/html/rfc5246).

If the data holder requires client authentication and/or authorization, then the client's HTTPS API request MUST present an OAuth 2.0 bearer access token as specified in [RFC 6750](https://tools.ietf.org/html/rfc6750), in the Authorization request header field with the Bearer authentication scheme:

```
Authorization: Bearer [access_token]
```

The policies and processes used to perform user authentication and authorization, and the means through which access tokens are issued, are beyond the scope of this API specification. GA4GH recommends the use of the OAuth 2.0 framework ([RFC 6749](https://tools.ietf.org/html/rfc6749)) for authentication and authorization.

## Checksum calculation
The recommended checksum algorithms are `MD5` (a 32 character HEX string) and a SHA-512 based system called `ga4gh` (a base64 URL-safe string, see later for details). Servers MUST support sequence retrieval by one or more of these algorithms, and are encouraged to support all to maximize interoperability. An older algorithm called `TRUNC512` existed in version 1.0.0 of refget but is now deprecated in favour of the GA4GH sequence checksum string. It is possible to translate between the `ga4gh` and `TRUNC512` systems however `TRUNC512` usage SHOULD be discouraged.

When calculating the checksum for a sequence, all non-base symbols (\n, spaces, etc) must be removed and then uppercase the rest. The allowed alphabet for checksum calculation is uppercase ASCII (`0x41`-`0x5A` or `A-Z`).

Resulting hexadecimal checksum strings shall be considered case insensitive. 0xa is equivalent to 0xA.

## refget Checksum Algorithm
The refget checksum algorithm is called `ga4gh`. It is based and derived from work carried out by the GA4GH VRS group. It is defined as follows:

- SHA-512 digest of a sanitised sequence
- A base64 url encoding of the first 24 bytes of that digest
- The addition of `SQ.` to the string

Services may also implement the older `TRUNC512` representation of a truncated SHA-512 digest and is compatible with the above `ga4gh` string. See later in this specification for implementation details of the TRUNC512 algorithm and conversion between `ga4gh` and `TRUNC512`.

A `ga4gh` digest of `ACGT` MUST result in the string `SQ.aKF498dAxcJAqme6QYQ7EZ07-fiw8Kw2`.

## Namespace of the checksums

The requested checksum can optionally be prefixed with a namespace describing the type of algorithm being used.
For example using md5 `md5:6aef897c3d6ff0c78aff06ac189178dd` and `6aef897c3d6ff0c78aff06ac189178dd` should return the same sequence and using ga4gh `ga4gh:SQ.aKF498dAxcJAqme6QYQ7EZ07-fiw8Kw2` and `SQ.aKF498dAxcJAqme6QYQ7EZ07-fiw8Kw2` should also return the same sequence.

## Unique Identifiers
Refget optionally allows the use of namespaced identifiers in place of the digest. The identifier prefixed by a namespace to form a CURIE for example:

`insdc:CM000663.2`

It is recommended that each namespaced identifier be unique within the refget implementation but if it does not resolve to a single sequence the server must respond with either:
 - code 300: `multiple choices` providing a list of identifiers or sequence digests that correspond to the request
 - code 409: `conflict` indicating a conflict that cannot be resolved.

## CORS
Cross-origin resource sharing (CORS) is an essential technique used to overcome the same origin content policy seen in browsers. This policy restricts a webpage from making a request to another website and leaking potentially sensitive information. However the same origin policy is a barrier to using open APIs. GA4GH open API implementers should enable CORS to an acceptable level as defined by their internal policy. For any public API implementations should allow requests from any server.

GA4GH is publishing a [CORS best practices document](https://docs.google.com/document/d/1Ifiik9afTO-CEpWGKEZ5TlixQ6tiKcvug4XLd9GNcqo/edit?usp=sharing), which implementers should refer to for guidance when enabling CORS on public API instances.

## API Methods

### Method: get sequence by ID

`GET /sequence/<id>`

The primary method for accessing specified sequence data. The response is the requested sequence or sub-sequence in text unless an alternative formatting supported by the server is requested.

The client may specify a genomic range to retrieve a sub-sequence via either the Range header OR start/end query parameters, however the Range header is the recommended method. If a sub-sequence is requested via `start`/`end` query parameters, the response must be 200 and only contain the specified sub-sequence. If a sub-sequence is requested via a Range header, the response must be one of 206 and only contain the specified sub-sequence, be 200 and contain the entire sequence (thus ignoring the Range header), or 303 redirecting the client to where it can retrieve the sequence.

If a sub-sequence is requested, the response must only contain the specified sub-sequence. A server may place a length limit on sub-sequences returned via query parameter, queries exceeding this limit shall return `Range Not Satisfiable`.

If `start` and `end` are set to the same value the server should return a 0-length string.

A server may support circular chromosomes as a reference sequence, but this is not mandatory. If a reference sequence represents a circular chromosome and the server supports circular chromosomes, a sub-sequence query with a start greater than the end will return the sequence from the start location to the end of the reference, immediately followed by the sequence from the first base to the end. If the server supports circular chromosomes and the chromosome is not circular or the range is outside the bounds of the chromosome the server shall return `Range Not Satisfiable`. Otherwise if circular chromosomes are not supported, a `Not Implemented` shall be returned. Sub-sequences of circular chromosomes across the origin may not be requested via the Range header. The starting point of a circular chromosome is determined by an external authority and not by the refget implementation.

##### Default encoding
Unless negotiated with the client and allowed by the server, the default encoding for this method is:

```
Content-type: text/vnd.ga4gh.refget.v2.0.0+plain
```

#### URL parameters

| Parameter | Data Type | Required | Description                                                                                                                                                                                                         |
|-----------|-----------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`      | string    | Yes      | A string specifying an identifier uniquely associated with a sequence so that at most one sequence is returned for an id. The id can be a checksum or other unique namespaced identifier supported by the server. |

#### Query parameters

| Parameter | Data Type               | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
|-----------|-------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `start`   | 32-bit unsigned integer | Optional | The start position of the range on the sequence, 0-based, inclusive. The server MUST respond with a `Bad Request` error if start is specified and is larger than the total sequence length. The server MUST respond with a `Range Not Satisfiable` error if start and end are specified and start is greater than end and the sequence is not a circular chromosome. Otherwise if the server does not support circular chromosomes it MUST respond with `Not Implemented` if the start is greater than the end. The server MUST respond with `Bad Request` if start and the Range header are both specified. |
| `end`     | 32-bit unsigned integer | Optional | The end position of the range on the sequence, 0-based, exclusive. The server MUST respond with a `Range Not Satisfiable` error if start and end are specified and start is greater than end and the sequence is not a circular chromosome. Otherwise if the server does not support circular chromosomes it MUST respond with `Not Implemented` if the start is greater than the end. The server MUST respond with `Bad Request` if end and the Range header are both specified.                                                                                                                            |

#### Request parameters

| Parameter | Data Type               | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
|-----------|-------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Range`   | string                  | Optional | Range header as specified in [RFC 7233](https://tools.ietf.org/html/rfc7233#section-3.1), however only a single byte range per GET request is supported by the specification. The byte range of the sequence to return, 0-based inclusive of start and end bytes specified. The server MUST respond with a `Bad Request` error if both a Range header and start or end query parameters are specified. The server MUST respond with a `Bad Request` error if one or more ranges are out of bounds of the sequence.                                                                                                                     |
| `Accept`    | string                  | Optional | The formatting of the returned sequence, defaults to `text/vnd.ga4gh.refget.v2.0.0+plain` if not specified. A server MAY support other formatting of the sequence.The server SHOULD respond with an `Not Acceptable` error if the client requests a format not supported by the server.                                                                                                                                                                                                                                                                                                                 |

#### Response

The server shall return the requested sequence or sub-sequence as a single string in uppercase ASCII text (bytes 0x41-0x5A) with no line terminators or other formatting characters. The server may return the sequence in an alternative formatting, such as JSON or FASTA, if requested by the client via the `Accept` header and the format is supported by the server.

On success and either a whole sequence or sub-sequence is returned the server MUST issue a 200 status code if the entire sequence is returned. A server SHOULD return a 206 status code if a Range header was specified and the request was successful.

If start and end query parameter are specified and equal each other, the server should respond with a zero length string i.e.

```
GET /sequence/6aef897c3d6ff0c78aff06ac189178dd?start=0&end=0

```

If a start and/or end query parameter are specified the server should include a `Accept-Ranges: none` header in the response.

If the identifier is not known by the server, a 404 status code and `NotFound` error shall be returned.

#### Example text request and response

The following response has been cut for brevity.

```
GET /sequence/6aef897c3d6ff0c78aff06ac189178dd
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN ....
```

### Method: Get known metadata for an id

```
GET /sequence/<id>/metadata
```

Return all known names for an identifier and related metadata.

Due to the possibility of multiple checksum algorithms being supported by a server, and potentially other known aliases for a sequence existing, this method allows clients to query all known names for a given identifier as well as fetch any associated metadata.

#### Default encoding
Unless negotiated with the client and allowed by the server, the default encoding for this method is:

```
Content-type: application/vnd.ga4gh.refget.v2.0.0+json
```

#### URL parameters

| Parameter | Data Type | Required | Description                                                                                                                                                                                                         |
|-----------|-----------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`      | string    | Yes      | A string specifying an identifier to retrieve metadata for using one of the defined checksum algorithms or a server-specific checksum algorithm.|

#### Request parameters

| Parameter | Data Type               | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
|-----------|-------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Accept`  | string                  | Optional | The formatting of the returned metadata, defaults to `application/vnd.ga4gh.refget.v2.0.0+json` if not specified. A server MAY support other formatting of the sequence.The server SHOULD respond with an `Not Acceptable` error if the client requests a format not supported by the server.                                                                                                                                                                                                                                                                                                                 |

#### Response

The server shall return a list of all identifiers for algorithms the server knows and the given identifier along with associated metadata. Identifiers provided by naming authorities should be provided in the `aliases` property. The server MAY return the query identifier in the list of identifiers.

A JSON encoded response shall have the following fields:

<table>
<tr markdown="block"><td>
<code>metadata</code><br/>
object
</td><td>
Container for response object.
<table>
<tr markdown="block"><td>
<code>md5</code><br/>
string
</td><td>
md5 checksum.
</td></tr>
<tr markdown="block"><td>
<code>ga4gh</code><br/>
string
</td><td>
  ga4gh identifier, if the server does not support ga4gh the value will be <code>null</code>.
</td></tr>
<tr markdown="block"><td>
<code>length</code><br/>
int
</td><td>
The length of the reference sequence.
</td></tr>
<tr markdown="block"><td>
<code>aliases</code><br/>
array of objects
</td><td>
Array of objects each containing one of the known aliases. The query identifier may be in this this.
<table>
<tr markdown="block"><td>
<code>alias</code><br/>
string
</td><td>
A known alias for the query.
</td></tr>
<tr markdown="block"><td>
<code>naming_authority</code><br/>
string
</td><td>
The source of the alias. See Appendix 1 for a set of recommended names to use.
</td></tr>
</table>
</td></tr>
</table>
</td></tr>
</table>

On success and the query identifier being known to the server, a 200 status code shall be returned.

If the identifier is not known by the server, a 404 status code shall be returned.

#### Example JSON request and response

```
GET /sequence/6aef897c3d6ff0c78aff06ac189178dd/metadata

{
  "metadata" : {
    "md5" : "6aef897c3d6ff0c78aff06ac189178dd",
    "ga4gh": "SQ.Ya6Rs7DHhDeg7YaOSg1EoNi3U_nQ9SvO",
    "length": 248956422,
    "aliases" : [
      {
        "alias": "CM000663.2",
        "naming_authority" : "insdc"
      },
      {
        "alias": "chr1",
        "naming_authority" : "ucsc"
      }
    ]
  }
}
```

### Method: Fetch information on the service

`GET /sequence/service-info`

Return configuration information about this server implementation. See the [service-info specification page](https://github.com/ga4gh-discovery/ga4gh-service-info) for more information.

#### Default encoding
Unless negotiated with the client and allowed by the server, the default encoding for this method is:

```
Content-type: application/vnd.ga4gh.refget.v2.0.0+json
```

#### Request parameters

| Parameter | Data Type               | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
|-----------|-------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Accept`  | string                  | Optional | The formatting of the returned metadata, defaults to `application/vnd.ga4gh.refget.v2.0.0+json` if not specified. A server MAY support other formatting of the sequence.The server SHOULD respond with an `Not Acceptable` error if the client requests a format not supported by the server.                                                                                                                                                                                                                                                                                                                 |

#### Response
The server shall return a document detailing specifications of the service implementation. A JSON encoded response shall have the following fields in addition to those specified by service-info:

<table>
<tr markdown="block"><td>
<code>refget</code><br/>
object
</td><td>
Container for response object.
<table>
<tr markdown="block"><td>
<code>circular_supported</code><br/>
boolean
</td><td>
If circular genomes are supported by the server.
</td></tr>
<tr markdown="block"><td>
<code>algorithms</code><br/>
array of enum(strings)
</td><td>
An array of strings listing the digest algorithms that are supported. Standard values: <code>md5</code>, <code>trunc512</code>, <code>ga4gh</code> (though others may be specified as a non-standard extension).
</td></tr>
<tr markdown="block"><td>
<code>identifier_types</code><br/>
array of strings
</td><td>
An array of strings listing the type identifiers supported. Values used should be the same as the one supported by [identifiers.org](https://registry.identifiers.org/registry) such as <code>insdc</code>, <code>ensembl</code>, <code>refseq</code>.
</td></tr>
<tr markdown="block"><td>
<code>subsequence_limit</code><br/>
int or null
</td><td>
An integer giving the maximum length of sequence which may be requested using <code>start</code> and/or <code>end</code> query parameters or <code>Range</code> header. <code>null</code> values or values lower than 1 or mean the server has no imposed limit.
</td></tr>
</table>
</td></tr>
</table>

#### Example JSON request and response

```
GET /service-info

{
  "id": "org.ga4gh.refget",
  "name": "Refget server",
  "type": {
    "group": "org.ga4gh",
    "artifact": "refget",
    "version": "2.0.0"
  },
  "description": "Reference sequences from checksums",
  "organization": {
    "name": "My organization",
    "url": "https://example.com"
  },
  "contactUrl": "mailto:support@example.com",
  "documentationUrl": "https://docs.myservice.example.com",
  "createdAt": "2019-06-04T12:58:19Z",
  "updatedAt": "2019-06-04T12:58:19Z",
  "environment": "prod",
  "version": "2.0.0",
  "refget": {
    "circular_supported": true,
    "subsequence_limit": 0,
    "algorithms": [
      "md5",
      "ga4gh",
      "trunc512"
    ],
    "identifier_types": [
      "insdc",
      "refseq",
      "ensembl"
    ]
  }
}
```

## Range headers

GA4GH has a standard of 0-based, half-open coordinates however Range requests as described in RFC 7233 use a unit of bytes starting at 0 and inclusive of the first and last byte specified (although other units are permitted by the RFC). For this reason care must be taken when making a request with a Range header versus start/end in the query string. Range start and end would be with respect to the byte coordinates of the sequence as if it were stored in a file on disk as a continuous string with no carriage returns.

RFC 7233 permits multiple byte ranges in a request, for this specification only a single byte range per GET request is permitted.

For example, given the following sequence:

```
CAACAGAGACTGCTGCTGACAGTGGGCGGGGGAGTAGTTTGCTTGGCCCGTGGTTGAGGA
```

And a Range header to retrieve 10bp:

```
Range: bytes=5-14
```

The returned sub-sequence would be:

```
GAGACTGCTG
```

However a start/end for the same 10bp would be:

```
?start=5&end=15
```

A Range header to retrieve a single base pair would be:

```
Range: bytes=0-0
```

The returned subsequence would be the first `C` of the sequence. A URL parameter for the same region would be

```
?start=0&end=1
```

Any formatting of the sequence a server might allow is applied after the sub-sequence is selected, for example a server that supported returning fasta the result for the prior example could be:

```
>9f5b68f3ebc5f7b06a9b2e2b55297403 5-14
GAGACTGCTG
```

Any bytes added for formatting to the returned output should not be taken in to account when processing a Range request.

## Alternative Checksum Algorithms

Refget implementations MUST support the `MD5` identifier space and SHOULD support the `ga4gh` identifier. Non-standard identifiers are allowed but they MUST conform to the following requirements:

1. Non-standard identifiers must be based on an algorithm, which uses normalised sequence content as input
2. The algorithm used SHOULD be a hash function
3. Non-standard identifiers must not clash with the `MD5` and `ga4gh` identifier space
  - Note `ga4gh` is allowed to grow in length should collisions in the current implementation be detected
4. Non-standard identifiers must not clash with other identifiers on your server i.e. they must be unique.

Any alternative identifier scheme MUST be declared in the `/sequence/service-info` endpoint under `algorithms`.

## ga4gh identifier and TRUNC512 Algorithm Details

Examples on how to implement both algorithm schemes in [Python](pub/ga4gh_and_TRUNC512_identifiers.ipynb) and [Perl](pub/ga4gh_and_TRUNC512_identifiers.pl) are available from this site.

## Design Rationale

This section details behind key API decisions.

### Checksum Input Normalisation

Key to generating reproducible checksums is the normalisation algorithm applied to sequence input. This API is based on the requirements of SAM/BAM, CRAM Reference Registry and VMC specifications. Both of these specs' own normalisation algorithms are detailed below:

- SAM/BAM
  - All characters outside of the inclusive range `33` (`0x21`/`!`) and `126` (`0x7E`/`~`) are stripped out
  - All lower-case characters are converted to upper-case
- CRAM Reference Registry
  - Input comes into the registry via ENA
  - ENA allows input conforming to the following regular expression `(?i)^([ACGTUMRWSYKVHDBN]+)\\*?$"`
- VRS
  - VRS requires sequence to be a string of IUPAC codes for either nucleotide or protein sequence

Considering the requirements of the three systems the specification designers felt it was sufficient to restrict input to the inclusive range `65` (`0x41`/`A`) to `90` (`0x5A`/`Z`). Changes to this normalisation algorithm would require a new checksum identifier to be used.

### Checksum Choice

MD5 provides adequate protection against hash collisions occurring from sequences. However the consequence of a sequence derived hash collision appearing would be catastrophic as two or more sequences with different content would report to be the same entity.

The VRS, Variation Representation Specification, is a complementary GA4GH effort to model genomic variation based on deviations from a reference sequence. Part of their work was to explore hashing algorithms. We have adopted the [checksum algorithm from VRS v1](https://vrs.ga4gh.org/en/1.0/impl-guide/computed_identifiers.html#truncated-digest-sha512t24u), based around the SHA-512 algorithm.

The algorithm performs a SHA-512 digest of a sequence and creates a `base64url` encoding ([using RFC 4648](https://datatracker.ietf.org/doc/html/rfc4648#section-5)) of the first 24 bytes of the digest. Analysis performed by VRS suggests this should be sufficient to avoid message collisions (see the VRS documentation for more details). Should a message collision occur within this scheme then the number of bytes retained from the SHA-512 checksum will be increased.

### Checksum Identifier Identification

When a checksum identifier is given to an implementation, it is the server's responsibility to compute what kind of identifier (`MD5`, `ga4gh` or `TRUNC512`) has been given. If provided, the namespace prefix should be used to figure it out. Otherwise `MD5` and `TRUNC512` can be deduced based on length; 32 and 48 characters long respectively. `ga4gh` identifiers can be detected by searching for the string `SQ.`. Should refget officially support alternative checksum based identifiers we will describe the mechanisms to resolve their identification in future versions.

## Possible Future API Enhancements

- Allow POST requests for batch downloads
- Formally define more sequence formatting options (e.g. fasta, protobuf)
- Allow reference sequence checksums to be bundled together e.g. to represent a reference genome
- Support groups/collections of sequences based on checksums

## Contributors

The following people have contributed to the design of this specification.

- Andy Yates
- Rob Davies
- Rasko Leinonen
- Oliver Hofmann
- Thomas Keane
- Heidi Sofia
- Mike Love
- Gustavo Glusman
- John Marshall
- Matthew Laird
- Somesh Chaturvedi
- Rishi Nag
- Reece Hart
- Timothe Cezard
- Reggan Thomas

# Appendix

## Appendix 1 - Naming Authorities

The specification makes no attempt to enforce a strict naming authority across implementations due to their potential heterogenous nature. However we do encourage implementors to reuse naming authority strings where possible following nomenclature from [identifiers.org](https://registry.identifiers.org/registry). See below for examples of recommended names.

| String     | Authority | Description | Status |
|------------|-----------|-------------|--------|
| `insdc`    | INSDC | Used for any identifier held in an INSDC resource (GenBank, ENA, DDBJ) | Active |
| `ucsc`     | UCSC | Used for an identifier assigned by UCSC Genome group | Active |
| `ensembl`  | Ensembl | Used for an identifier assigned by the Ensembl project | Active |
| `md5`  | MD5 | Prefix used to describe digests which have gone through the MD5 algorithm | Active |
| `refseq`   | RefSeq | Used for an identifier assigned by the RefSeq group | Active |
| `trunc512` | Refget | The old checksum algorithm based on SHA-512 used in v1.0.0 of refget | Deprecated |
| `ga4gh`    | Refget | ga4gh identifier, which are prefixed by the term `SQ.`. This is the preferred naming | Active |
| `md5`    | Refget | md5 checksum of the sequence. | Active |
| `vmc`      | VMC | Used for when an identifier is a VMC compatible digest | Deprecated |

## Appendix 2 - Changes

### v2.0.0

- Replace refget's v1 service-info implementation with GA4GH discovery's definition of service-info
- Move code examples out into a Python notebook and a Perl script
- Replace TRUNC512 with ga4gh identifier as the default SHA-512 based hash identifier (support still available for TRUNC512)
- All checksums can be requested namespaced with their algorithm
- Optional support for namespaced identifiers to resolve sequence and metadata
- Lower cased recommended naming authority strings

### v1.0.1

[Specification link](https://github.com/samtools/hts-specs/blob/fde0b700d7d1aeb4d40cc27c820965a6f365f650/refget.md)

- `plain/text` responses no longer need to specify a VND. `application/json` responses continue to need to do this.

### v1.0.0

[Specification link](https://github.com/samtools/hts-specs/blob/f7947e7554f289a9bf0027be93be4145b97243a2/refget.md)

- First release of the specification
