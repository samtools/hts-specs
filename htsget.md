---
layout: default
title: htsget protocol
suppress_footer: true
---

# Htsget retrieval API spec v0.1

# Design principles

This data retrieval API bridges from existing genomics bulk data transfers to a client/server model with the following features:

* Incumbent data formats (BAM, CRAM) are preferred initially, with a future path to others.
* Multiple server implementations are supported, including those that do format transcoding on the fly, and those that return essentially unaltered filesystem data.
* Multiple use cases are supported, including access to small subsets of genomic data (e.g. for browsing a given region) and to full genomes (e.g. for calling variants).
* Clients can provide hints of the information to be retrieved; servers can respond with more information than requested but not less.
* We use the following pan-GA4GH standards:
   * 0 start, half open coordinates
   * The structuring of POST inputs, redirects and other non-reads data will be protobuf3 compatible JSON

Explicitly this API does NOT:

* Provide a way to discover the identifiers for valid ReadGroupSets --- clients obtain these via some out of band mechanism


# Protocol essentials

All API invocations are made to a configurable HTTP(S) endpoint, receive URL-encoded query string parameters, and return JSON output. Successful requests result with HTTP status code 200 and have UTF8-encoded JSON in the response body, with the content-type `application/json`. The server may provide responses with chunked transfer encoding. The client and server may mutually negotiate HTTP/2 upgrade using the standard mechanism.

Any timestamps that appear in the response from an API method are given as [ISO 8601] date/time format.

HTTP responses may be compressed using [RFC 2616] `transfer-coding`, not `content-coding`.

## Authentication

Requests to the retrieval API endpoint may be authenticated by means of an OAuth2 bearer token included in the request headers, as detailed in [RFC 6750]. Briefly, the client supplies the header `Authorization: Bearer xxxx` with each HTTPS request, where `xxxx` is a private token. The mechanisms by which clients originally obtain their authentication tokens, and by which servers verify them, are currently beyond the scope of this specification. Servers may honor non-authenticated requests at their discretion.

## Errors

Non-successful invocations of the API return an HTTP error code, and the response body contains a JSON object (content-type application/json) with the following structure:

```json
{
   "error": {
       "type": "NotFound",
       "message": "No such accession"
   }
}
```

The following error types are defined:

|-
Type			| HTTP status code | Description
|-
InvalidAuthentication	| 401	| Authorization provided is invalid
PermissionDenied	| 403	| Authorization is required to access the resource
NotFound		| 404	| The resource requested was not found
Unable			| 406	| The server is unable to fulfill the request
UnsupportedFormat	| 409	| The requested file format is not supported by the server
InvalidInput		| 422	| The request parameters do not adhere to the specification
InternalError		| 500	| Server error, clients should try later
ServiceUnavailable	| 503	| Service is temporarily unavailable
|-

## CORS

All API resources should have the following support for cross-origin resource sharing ([CORS]) to support browser-based clients:

If a request to the URL of an API method includes the `Origin` header, its contents will be propagated into the `Access-Control-Allow-Origin` header of the response. Preflight requests (`OPTIONS` requests to the URL of an API method, with appropriate extra headers as defined in the CORS specification) will be accepted if the value of the `Access-Control-Request-Method` header is `GET`.
The values of `Origin` and `Access-Control-Request-Headers` (if any) of the request will be propagated to `Access-Control-Allow-Origin` and `Access-Control-Allow-Headers` respectively in the preflight response.
The `Access-Control-Max-Age` of the preflight response is set to the equivalent of 30 days.


# Method: get reads by ID

    GET /reads/<id>

The core mechanic for accessing specified reads data. The JSON response is a "ticket" allowing the caller to obtain the desired data in the specified format, which may involve follow-on requests to other endpoints, as detailed below.

The client can request only reads overlapping a given genomic range. The response may however contain a superset of the desired results, including all records overlapping the range, and potentially other records not overlapping the range; the client should filter out such extraneous records if necessary. Successful requests with empty result sets still produce a valid response in the requested format (e.g. including header and EOF marker).

## URL parameters

<table>
<tr markdown="block"><td>
`id`  
_required_
</td><td>
A string specifying which reads to return.

The format of the string is left to the discretion of the API provider, including allowing embedded "/" characters. Strings could be ReadGroupSetIds as defined by the GA4GH API, or any other format the API provider chooses (e.g. "/data/platinum/NA12878", "/byRun/ERR148333").
</td></tr>
</table>

## Query parameters

<table>
<tr markdown="block"><td>
`format`  
_optional string_
</td><td>
Request read data in this format. Default: BAM. Allowed values: BAM,CRAM.

Server replies with HTTP status 409 if the requested format is not supported.
[^a]
</td></tr>
<tr markdown="block"><td>
`referenceName` 
_optional_
</td><td>
The reference sequence name, for example "chr1", "1", or "chrX". If unspecified, all reads (mapped and unmapped) are returned. [^b]
</td></tr>
<tr markdown="block"><td>
`referenceMD5`  
_optional_
</td><td>
The MD5 checksum uniquely representing the reference sequence as a lower-case hexadecimal string, calculated as the MD5 of the upper-case sequence excluding all whitespace characters (this is equivalent to SQ:M5 in SAM).

Server replies with HTTP status 422 if `referenceName` and `referenceMD5` are both specified and are incompatible.
</td></tr>
<tr markdown="block"><td>
`start`  
_optional 32-bit unsigned integer_
</td><td>
The start position of the range on the reference, 0-based, inclusive. If specified, `referenceName` or `referenceMD5` must also be specified. [^c]
</td></tr>
<tr markdown="block"><td>
`end`  
_optional 32-bit unsigned integer_
</td><td>
The end position of the range on the reference, 0-based exclusive. If specified, `referenceName` or `referenceMD5` must also be specified.
</td></tr>
<tr markdown="block"><td>
`fields`  
_optional_
</td><td>
A list of fields to include, see below
Default: all
</td></tr>
<tr markdown="block"><td>
`tags`  
_optional_
</td><td>
A comma separated list of tags to include, default: all. If the empty string is specified (tags=) no tags are included. It is illegal for the values of `tags` and `notags` to intersect; the server may return HTTP status 400 in this case.
</td></tr>
<tr markdown="block"><td>
`notags`  
_optional_
</td><td>
A comma separated list of tags to exclude, default: none. It is illegal for the values of `tags` and `notags` to intersect; the server may return HTTP status 400 in this case.
</td></tr>
</table>

### Field filtering

The list of fields is based on BAM fields:

|-
Field	| Description
|-
QNAME	| Read names
FLAG	| Read bit flags
RNAME	| Reference sequence name
POS	| Alignment position
MAPQ	| Mapping quality score
CIGAR	| CIGAR string
RNEXT	| Reference sequence name of the next fragment template
PNEXT	| Alignment position of the next fragment in the template
TLEN	| Inferred template size
SEQ	| Read bases
QUAL	| Base quality scores
|-

Example: `fields=QNAME,FLAG,POS`.

## Response JSON fields

<table>
<tr markdown="block"><td>
`format`  
_string_
</td><td>
Read data format. Default: BAM. Allowed values: BAM,CRAM.
</td></tr>
<tr markdown="block"><td>
`urls`  
_array of objects_
</td><td>
An array providing URLs from which raw data can be retrieved. The client must retrieve binary data blocks from each of these URLs and concatenate them to obtain the complete response in the requested format.

Each element of the array is a JSON object with the following fields:

<table>
<tr markdown="block"><td>
`url`  
_string_
</td><td>
One URL.

May be either a `https:` URL or an inline `data:` URI. HTTPS URLs require the client to make a follow-up request (possibly to a different endpoint) to retrieve a data block. Data URIs provide a data block inline, without necessitating a separate request.

Further details below.
</td></tr>
<tr markdown="block"><td>
`headers`  
_optional object_
</td><td>
For HTTPS URLs, the server may supply a JSON object containing one or more string key-value pairs which the client MUST supply as headers with any request to the URL. For example, if headers is `{"Range": "bytes=0-1023", "Authorization": "Bearer xxxx"}`, then the client must supply the headers `Range: bytes=0-1023` and `Authorization: Bearer xxxx` with the HTTPS request to the URL.
</td></tr>
</table>

</td></tr>
<tr markdown="block"><td>
`md5`  
_optional hex string_
</td><td>
MD5 digest of the blob resulting from concatenating all of the "payload" data --- the url data blocks.
</td></tr>
</table>

## Response data blocks

### Diagram of core mechanic

![Diagram showing ticket flow](pub/htsget-ticket.png)

1. Client sends a request with id, genomic range, and filter.
2. Server replies with a ticket describing data block locations (URLs and headers).
3. Client fetches the data blocks using the URLs and headers.
4. Client concatenates data blocks to produce local blob.

While the blocks must be finally concatenated in the given order, the client may fetch them in parallel.

### HTTPS data block URLs

1. must have percent-encoded path and query (e.g. javascript encodeURIComponent; python urllib.urlencode)
2. must accept GET requests
3. should provide CORS
4. should allow multiple request retries, within reason
5. should use HTTPS rather than plain HTTP except for testing or internal-only purposes (for security + in-flight corruption detection)
6. Server must send the response with either the Content-Length header, or chunked transfer encoding, or both. Clients must detect premature response truncation.
7. Client and URL endpoint may mutually negotiate HTTP/2 upgrade using the standard mechanism.
8. Client must follow 3xx redirects from the URL, subject to typical fail-safe mechanisms (e.g. maximum number of redirects), always supplying the headers, if any.
If a byte range HTTP header accompanies the URL, then the client MAY decompose this byte range into several sub-ranges and open multiple parallel, retryable requests to fetch them. (The URL and headers must be sufficient to authorize such behavior by the client, within reason.)

### Inline data block URIs

e.g. `data:application/vnd.ga4gh.bam;base64,SGVsbG8sIFdvcmxkIQ==` ([RFC 2397], [Data URI]).
The client obtains the data block by decoding the embedded base64 payload.

1. must use base64 payload encoding (simplifies client decoding logic)
2. client should ignore the media type (if any), treating the payload as a partial blob.

Note: the base64 text should not be additionally percent encoded.

### Reliability & performance considerations

To provide robustness to sporadic transfer failures, servers should divide large payloads into multiple data blocks in the `urls` array. Then if the transfer of any one block fails, the client can retry that block and carry on, instead of starting all over. Clients may also fetch blocks in parallel, which can improve throughput.

Initial guidelines, which we expect to revise in light of future experience:
* Data blocks should not exceed ~1GB
* Inline data URIs should not exceed a few megabytes

### Security considerations

The URL and headers might contain embedded authentication tokens; therefore, production clients and servers should not unnecessarily print them to console, write them to logs, embed them in error messages, etc.

## Method-specific error interpretations

* 406 Unable: may be returned if a genomic range is requested, but the server is unable to provide genomic range slicing for the particular dataset (e.g. if no index is available).


# Possible future enhancements

1. add a mechanism to request reads from more than one ID at a time (e.g. for a trio)
2. allow clients to provide a suggested data block size to the server
3. consider adding other data types (e.g. variants)
4. add POST support (if and when request sizes get large)
5. [mlin] add a way to request all unmapped reads (e.g. by passing `*` for `referenceName`)
6. [dglazer] add a way to request reads in GA4GH binary format [^d] (e.g. fmt=proto)

## Existing clarification suggestions

[^a]: This should probably be specified as a (comma separated?) list in preference order.  If the client can accept both BAM and CRAM it is useful for it to indicate this and let the server pick whichever format it is most comfortable with.
[^b]: Define error code (404?, 416?) for queries to a reference that is not present in the header.  (Note this is not the same as present but having no data aligned to it - that should just be an empty reply.)
[^c]: Define error response codes - suggest 416 (range not satisfiable).  Perhaps this is appropriate for all chr, start and end failures.
[^d]: How will compression work in this case - can we benefit from columnar compression as does Parquet?


[CORS]:     http://www.w3.org/TR/cors/
[Data URI]: https://en.wikipedia.org/wiki/Data_URI_scheme
[ISO 8601]: http://www.iso.org/iso/iso8601
[RFC 2397]: https://www.ietf.org/rfc/rfc2397.txt
[RFC 2616]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html
[RFC 6750]: https://tools.ietf.org/html/rfc6750

<!-- vim:set linebreak: -->
