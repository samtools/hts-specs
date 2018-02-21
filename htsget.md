---
layout: default
title: htsget protocol
suppress_footer: true
---

# Htsget retrieval API spec v1.2.1

# Design principles

This data retrieval API bridges from existing genomics bulk data transfers to a client/server model with the following features:

* Incumbent data formats (BAM, CRAM) are preferred initially, with a future path to others.
* Multiple server implementations are supported, including those that do format transcoding on the fly, and those that return essentially unaltered filesystem data.
* Multiple use cases are supported, including access to small subsets of genomic data (e.g. for browsing a given region) and to full genomes (e.g. for calling variants).
* Clients can provide hints of the information to be retrieved; servers can respond with more information than requested but not less.
* We use the following conventions:
   * 0 start, half open coordinates
   * JSON format for signaling messages (redirect responses & POST request bodies), describable by [OpenAPI Schemas](https://swagger.io/docs/specification/data-models/)

Explicitly this API does NOT:

* Provide a way to discover the identifiers for valid ReadGroupSets --- clients obtain these via some out of band mechanism

This protocol specification is accompanied by a [corresponding OpenAPI description](pub/htsget-openapi.yaml). OpenAPI is a language-independent way of describing REST services and is compatible with a number of [third party tools](http://openapi.tools/).
(Note: if there are differences between this text and the OpenAPI description, this specification text is definitive.)

# Protocol essentials

All API invocations are made to a configurable HTTP(S) endpoint, receive URL-encoded query string parameters, and return JSON output. Successful requests result with HTTP status code 200 and have UTF8-encoded JSON in the response body. The server may provide responses with chunked transfer encoding. The client and server may mutually negotiate HTTP/2 upgrade using the standard mechanism.

The JSON response is an object with the single key `htsget` as described in the [Response JSON fields](#response-json-fields) and [Error Response JSON fields](#error-response-json-fields) sections.  This ensures that, apart from whitespace differences, the message always starts with the same prefix.  The presence of this prefix can be used as part of a client's response validation.

Any timestamps that appear in the response from an API method are given as [ISO 8601] date/time format.

HTTP responses may be compressed using [RFC 2616] `transfer-coding`, not `content-coding`.

Requests adhering to this specification MAY include an `Accept` header specifying the htsget protocol version they are using:

    Accept: application/vnd.ga4gh.htsget.v1.0.0+json

JSON responses SHOULD include a `Content-Type` header describing the htsget protocol version defining the JSON schema used in the response, e.g.,

    Content-Type: application/vnd.ga4gh.htsget.v1.0.0+json; charset=utf-8

## Errors

The server MUST respond with an appropriate HTTP status code (4xx or 5xx) when an error condition is detected.  In the case of transient server errors, (e.g., 503 and other 5xx status codes), the client SHOULD implement appropriate retry logic as discussed in [Reliability & performance considerations](#reliability--performance-considerations) below.

For errors that are specific to the `htsget` protocol, the response body SHOULD be a JSON object (content-type `application/json`) providing machine-readable information about the nature of the error, along with a human-readable description. The structure of this JSON object is described as follows.

### Error Response JSON fields

<table>
<tr markdown="block"><td>

`htsget`
_object_
</td><td>
Container for response object.
<table>
<tr markdown="block"><td>

`error`  
_string_
</td><td>
The type of error. This SHOULD be chosen from the list below.
</td></tr>
<tr markdown="block"><td>

`message`  
_string_
</td><td>
A message specific to the error providing information on how to debug the problem. Clients MAY display this message to the user.
</td></tr>
</table>
</td></tr>
</table>

The following errors types are defined:

Error type	| HTTP status code | Description
|-----|:---:|-----|
InvalidAuthentication	| 401	| Authorization provided is invalid
PermissionDenied	| 403	| Authorization is required to access the resource
NotFound		| 404	| The resource requested was not found
PayloadTooLarge         | 413   | POST request size is too large
UnsupportedFormat	| 400	| The requested file format is not supported by the server
InvalidInput		| 400	| The request parameters do not adhere to the specification
InvalidRange		| 400	| The requested range cannot be satisfied

The error type SHOULD be chosen from this table and be accompanied by the specified HTTP status code.  An example of a valid JSON error response is:
```json
{
   "htsget" : {
      "error": "NotFound",
      "message": "No such accession 'ENS16232164'"
   }
}
```
## Security

The htsget API enables the retrieval of potentially sensitive genomic data by means of a client/server model. Effective security measures are essential to protect the integrity and confidentiality of these data.

Sensitive information transmitted on public networks, such as access tokens and human genomic data, MUST be protected using Transport Level Security (TLS) version 1.2 or later, as specified in [RFC 5246](https://tools.ietf.org/html/rfc5246).

If the data holder requires client authentication and/or authorization, then the client's HTTPS API request MUST present an OAuth 2.0 bearer access token as specified in [RFC 6750](https://tools.ietf.org/html/rfc6750), in the `Authorization` request header field with the `Bearer` authentication scheme:

```
Authorization: Bearer [access_token]
```

The policies and processes used to perform user authentication and authorization, and the means through which access tokens are issued, are beyond the scope of this API specification. GA4GH recommends the use of the OAuth 2.0 framework ([RFC 6749](https://tools.ietf.org/html/rfc6749)) for authentication and authorization.

## CORS

All API resources should have the following support for cross-origin resource sharing ([CORS]) to support browser-based clients:

If a request to the URL of an API method includes the `Origin` header, its contents will be propagated into the `Access-Control-Allow-Origin` header of the response. Preflight requests (`OPTIONS` requests to the URL of an API method, with appropriate extra headers as defined in the CORS specification) will be accepted if the value of the `Access-Control-Request-Method` header is `GET`.
The values of `Origin` and `Access-Control-Request-Headers` (if any) of the request will be propagated to `Access-Control-Allow-Origin` and `Access-Control-Allow-Headers` respectively in the preflight response.
The `Access-Control-Max-Age` of the preflight response is set to the equivalent of 30 days.

# GET request

## Methods

The recommended endpoints to access reads and variants data are:

    GET /reads/<id>
    GET /variants/<id>

The JSON response is a "ticket" allowing the caller to obtain the desired data in the specified format, which may involve follow-on requests to other endpoints, as detailed below.

The client can request only records overlapping a given genomic range. The response may however contain a superset of the desired results, including all records overlapping the range, and potentially other records not overlapping the range; the client should filter out such extraneous records if necessary. Successful requests with empty result sets still produce a valid response in the requested format (e.g. including header and EOF marker).

## URL parameters

<table>
<tr markdown="block"><td>

`id`  
_required_
</td><td>

A string identifying which records to return.

The format of this identifier is left to the discretion of the API provider, including allowing embedded "/" characters. The following would be valid identifiers:

* ReadGroupSetIds or VariantSetIds as defined by the GA4GH API
* Studies: PRJEB4019 or /byStudy/PRJEB4019
* Samples: NA12878 or /data/platinum/NA12878
* Runs: ERR148333 or /byRun/ERR148333

The id `service-info` SHOULD be reserved to serve GA4GH service-info metadata, detailed below.

</td></tr>
</table>

## Query parameters

<table>
<tr markdown="block"><td>

`format`  
_optional string_
</td><td>

Request data in this format. The allowed values for each type of record are:

* Reads: BAM (default), CRAM.
* Variants: VCF (default), BCF.

The server SHOULD reply with an `UnsupportedFormat` error if the requested format is not supported.
[^a]
</td></tr>
<tr markdown="block"><td>

`class`  
_optional string_
</td><td>

Request different classes of data.
By default, i.e., when `class` is not specified, the response will represent a complete read or variant data stream, encompassing SAM/CRAM/VCF headers, body data records, and EOF marker.

If `class` is specified, its value MUST be one of the following:
<table>
<tr markdown="block"><td>

`header`
</td><td>

Request the SAM/CRAM/VCF headers only.

The server SHOULD respond with an `InvalidInput` error if any other htsget query parameters other than `format` are specified at the same time as `class=header`.
</td></tr>
</table>
</td></tr>
<tr markdown="block"><td>

`referenceName`  
_optional_
</td><td>

The reference sequence name, for example "chr1", "1", or "chrX". If unspecified, all records are returned regardless of position.

For the reads endpoint: if "\*", unplaced unmapped reads are returned. If unspecified, all reads (mapped and unmapped) are returned. (*Unplaced unmapped* reads are the subset of unmapped reads completely without location information, i.e., with RNAME and POS field values of "\*" and 0 respectively. See the [SAM specification](http://samtools.github.io/hts-specs/SAMv1.pdf) for details of placed and unplaced unmapped reads.)

The server SHOULD reply with a `NotFound` error if the requested reference does not exist.
</td></tr>
<tr markdown="block"><td>

`start`  
_optional 32-bit unsigned integer_
</td><td>

The start position of the range on the reference, 0-based, inclusive. 

The server SHOULD respond with an `InvalidInput` error if `start` is specified and either no reference is specified or `referenceName` is "\*".

The server SHOULD respond with an `InvalidRange` error if `start` and `end` are specified and `start` is greater than `end`.
</td></tr>
<tr markdown="block"><td>

`end`  
_optional 32-bit unsigned integer_
</td><td>

The end position of the range on the reference, 0-based exclusive.

The server SHOULD respond with an `InvalidInput` error if `end` is specified and either no reference is specified or `referenceName` is "\*".

The server SHOULD respond with an `InvalidRange` error if `start` and `end` are specified and `start` is greater than `end`.
</td></tr>
<tr markdown="block"><td>

`fields`  
_optional_
</td><td>
A list of fields to include, see below.
Default: all
</td></tr>
<tr markdown="block"><td>

`tags`  
_optional_
</td><td>

A comma separated list of tags to include, default: all. If the empty string is specified (tags=) no tags are included. 

The server SHOULD respond with an `InvalidInput` error if `tags` and `notags` intersect.
</td></tr>
<tr markdown="block"><td>

`notags`  
_optional_
</td><td>

A comma separated list of tags to exclude, default: none. 

The server SHOULD respond with an `InvalidInput` error if `tags` and `notags` intersect.
</td></tr>
</table>

### Field filtering

The list of fields is based on BAM fields:

Field	| Description
|-------|-------|
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

Example: `fields=QNAME,FLAG,POS`.

# POST request

In addition to the GET method, servers may optionally also accept POST requests.
The main differences to the GET method are that query parameters are encoded in JSON format and it is possible to request data for more than one genomic range.
The data returned is a JSON "ticket", as described for the GET method.

Htsget POST requests must be "safe" as defined in section 4.2.1 of [RFC 7231], that is they must be essentially read-only.

It should be expected that htsget servers will have a limit on the size of POST request that they can accept.
If an incoming POST request is too large, the server SHOULD reply with a `PayloadTooLarge` error.

## URL parameters

POST and GET requests should use the same URLs.

POST requests MUST NOT use and of the query parameters defined for GET requests on the URL.
If query parameters are present, the server SHOULD reply with an `InvalidInput` error.

## Request body

The POST request body is a JSON object containing the request parameters,
which have similar names and meanings to those used in the GET query.
A notable difference is that the  `referenceName`, `start` and `end` parameters are not used at the top level of the JSON object.
Instead as they are put into an array under the `regions` key, which allows more than one range to be specified.

<table><tbody><tr markdown="block"><td>

`format`  _optional string_
</td><td>

Request data in this format.
The allowed values for each type of record are:

* Reads: BAM (default), CRAM.
* Variants: VCF (default), BCF.

The server SHOULD reply with an `UnsupportedFormat` error if the requested format is not supported.
</td></tr>
<tr markdown="block"><td>

`class`
_optional string_
</td><td>

Request different classes of data.
As for GET requests, if `class` is not specified the response will comprise the full data stream including file headers, body data records and EOF marker.
If `class` is specified, its value MUST be one of the following:

<table>
<tr markdown="block"><td>

`header`
</td><td>

Request the SAM/CRAM/VCF headers only.

The server SHOULD respond with an `InvalidInput` error if any parameters other than `format` are specified at the same time as `"class" : "header"`.
</td></tr>
</table>
</td></tr>

`fields`  _optional array of strings_
</td><td>

List of fields to include.  See Field filtering.
  <table><tbody><tr markdown="block"><td>

Field name _string_
  </td></tr></tbody></table>
</td></tr>
<tr markdown="block"><td>

`tags`  _optional array of strings_
</td><td>

List of tags to include, default: all.  If an empty array is specified, no tags are included.

The server SHOULD respond with an `InvalidInput` error if `tags` and `notags` intersect.
  <table><tbody><tr markdown="block"><td>

Tag name _string_
  </td></tr></tbody></table>
</td></tr>
<tr markdown="block"><td>

`notags`  _optional array of strings_
</td><td>

List of tags to exclude, default: none.

The server SHOULD respond with an `InvalidInput` error if `tags` and `notags` intersect.
  <table><tbody><tr markdown="block"><td>

Tag name _string_
  </td></tr></tbody></table>
</td></tr>
<tr markdown="block"><td>

`regions` _optional array of objects_
</td><td>

Regions to return.

If not present, the entire file will be returned.
When present, the array must contain at least one region specification.
Note that regions will be returned in the order that they appear in the file, which may not match the order in the list.
Any overlapping regions will be merged.

The server SHOULD respond with an `InvalidInput` error if the region list is empty or not well-formed.
  <table><tbody><tr markdown="block"><td>

`referenceName` _string_
  </td><td>

The reference sequence name, for example "chr1", "1", or "chrX".

The server SHOULD respond with an `InvalidInput` error if `referenceName` is not specified.

The server SHOULD reply with a `NotFound` error if the requested reference does not exist.
  </td></tr>
  <tr markdown="block"><td>

`start` _optional unsigned integer_
  </td><td>

The start position of the range on the reference, 0-based, inclusive.

If not present, data will be returned starting from the first base in `referenceName`.

The server SHOULD respond with an `InvalidRange` error if `start` and `end`
are specified and `start` is greater than or equal to `end`.
  </td></tr>
  <tr markdown="block"><td>

`end` _optional unsigned integer_
  </td><td>

The end position of the range on the reference, 0-based exclusive.

If not present, data will be returned up to the end of the reference.

The server SHOULD respond with an `InvalidRange` error if `start` and `end`
are specified and `start` is greater than or equal to `end`.
  </td></tr></tbody></table>
</td></tr></tbody></table>

### Example

```json
{
   "format" : "bam",
   "fields" : ["QNAME", "FLAG", "RNAME", "POS", "CIGAR", "SEQ"],
   "tags" : ["RG"],
   "notags" : ["OQ"],
   "regions" : [
      { "referenceName" : "chr1" },
      { "referenceName" : "chr2", "start" : 999, "end" : 1000 },
      { "referenceName" : "chr2", "start" : 2000, "end" : 2100 }
   ]
}
```

## Region list

The `regions` parameter is an array of objects which describe the locations to be returned.
Each location object contains a `referenceName`, which must always be present, and optional `start` and `end` tags.

The first region in the example above shows how to return all reads for reference "chr1".

To return reads covering a single base, the client should use an end position one greater than the start, as shown in the second region in the example which requests the 1000th base of reference "chr2".

The regions list acts as a filter on the requested file.
Records that overlap the requested regions will be returned in the order that they occurred in the original file.
This may not be the same as the order in the list.
A record will only be returned once, even if it matches more than one location in the list.

As with the GET request, the server response may contain a super-set of the desired results.
Clients will need to filter out any extraneous records if necessary.

# Response

## Response JSON fields

<table>
<tr markdown="block"><td>

`htsget`
_object_
</td><td>
Container for response object.
<table>
<tr markdown="block"><td>

`format`  
_string_
</td><td>
Response data in this format. The allowed values for each type of record are:

* Reads: BAM (default), CRAM.
* Variants: VCF (default), BCF.
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
<tr markdown="block"><td>

`class`
_optional string_
</td><td>

For file formats whose specification describes a header and a body, the class indicates which of the two will be retrieved when querying this URL. The allowed values are `header` and `body`.

Either all or none of the URLs in the response MUST have a class attribute.
If `class` fields are not supplied, no assumptions can be made about which data blocks contain headers, body records, or parts of both.
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
</td></tr>
</table>

An example of a JSON response is:
```json
{
   "htsget" : {
      "format" : "BAM",
      "urls" : [
         {
            "url" : "data:application/vnd.ga4gh.bam;base64,QkFNAQ==",
            "class" : "header"
         },
         {
            "url" : "https://htsget.blocksrv.example/sample1234/header",
            "class" : "header"
         },
         {
            "url" : "https://htsget.blocksrv.example/sample1234/run1.bam",
            "headers" : {
               "Authorization" : "Bearer xxxx",
               "Range" : "bytes=65536-1003750"
             },
            "class" : "body"
         },
         {
            "url" : "https://htsget.blocksrv.example/sample1234/run1.bam",
            "headers" : {
               "Authorization" : "Bearer xxxx",
               "Range" : "bytes=2744831-9375732"
            },
            "class" : "body"
         }
      ]
   }
}
```

## Response data blocks

### Diagram of core mechanic

![Diagram showing ticket flow](pub/htsget-ticket.png)

1. Client sends a request with id, genomic range, and filter.
2. Server replies with a ticket describing data block locations (URLs and headers).
3. Client fetches the data blocks using the URLs and headers.
4. Client concatenates data blocks to produce local blob.

While the blocks must be finally concatenated in the given order, the client may fetch them in parallel and/or reuse cached data from URLs that have previously been downloaded.

When making a series of requests to fetch reads or variants within different regions of the same `<id>` resource, clients may wish to avoid re-fetching the SAM/CRAM/VCF headers each time, especially if they are large.
If the ticket contains `class` fields, the client may reuse previously downloaded and parsed headers rather than re-fetching the `header`-class URLs.

### HTTPS data block URLs

1. must have percent-encoded path and query (e.g. javascript encodeURIComponent; python urllib.urlencode)
2. must accept GET requests
3. should provide CORS
4. should allow multiple request retries, within reason
5. should use HTTPS rather than plain HTTP except for testing or internal-only purposes (providing both security and robustness to data corruption in flight)
6. need not use the same authentication scheme as the API server. URL and `headers` must include any temporary credentials necessary to access the data block. Client must not send the bearer token used for the API, if any, to the data block endpoint, unless copied in the required `headers`.
7. Server must send the response with either the Content-Length header, or chunked transfer encoding, or both. Clients must detect premature response truncation.
8. Client and URL endpoint may mutually negotiate HTTP/2 upgrade using the standard mechanism.
9. Client must follow 3xx redirects from the URL, subject to typical fail-safe mechanisms (e.g. maximum number of redirects), always supplying the `headers`, if any.
10. If a byte range HTTP header accompanies the URL, then the client MAY decompose this byte range into several sub-ranges and open multiple parallel, retryable requests to fetch them. (The URL and `headers` must be sufficient to authorize such behavior by the client, within reason.)

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

The data block URL and headers might contain embedded authentication tokens; therefore, production clients and servers should not unnecessarily print them to console, write them to logs, embed them in error messages, etc.

# GA4GH service-info

Following the [GA4GH service-info specification](https://github.com/ga4gh-discovery/ga4gh-service-info), htsget servers SHOULD also expose `/reads/service-info` and/or `/variants/service-info` metadata endpoints. In addition to the standard service-info fields, including `{"type": {"group": "org.ga4gh", "artifact": "htsget", "version": "x.y.z"}}`, the response SHOULD include an `htsget` object further describing htsget-specific capabilities, with the following fields:

<table>

<tr markdown="block"><td>

`datatype`  
_optional string_
</td><td>
Indicates the htsget datatype category ('reads' or 'variants') served by the ticket endpoint related to this service-info endpoint. Use either:

* reads
* variants
</td></tr>
<tr markdown="block"><td>

`formats`  
_optional array of strings_
</td><td>

List of requested `format` that can be satisfied. Allowed values:

* reads: BAM and/or CRAM
* variants: VCF and/or BCF
</td></tr>
<tr markdown="block"><td>

`fieldsParameterEffective`  
_optional boolean_
</td><td>

Indicates whether the service is capable of returning only a subset of available fields based on the `fields` query parameter.
</td></tr>
<tr markdown="block"><td>

`tagsParametersEffective`  
_optional boolean_  
</td><td>

Indicates whether the service is capable of server-side result tag inclusion/exclusion using the `tags` and `notags` query parameters.
</td></tr>
</table>

Example service-info response:

```
{ 
   "id":            "net.exampleco.htsget",
   "name":          "ExampleCo genomics data service",
   "version":       "0.1.0",
   "organization":  {
      "name":       "ExampleCo",
      "url":        "https://exampleco.com"
   },
   "type":  {
      "group":        "org.ga4gh",
      "artifact":     "htsget",
      "version":      "1.2.1"
   },
   "htsget": {
      "datatype": "reads",
      "formats":  ["BAM", "CRAM"],
      "fieldsParameterEffective": true,
      "tagsParametersEffective": false
   }
}
```

# GA4GH Service Registry

The [GA4GH Service Registry API specification](https://github.com/ga4gh-discovery/ga4gh-service-registry) allows information about GA4GH-compliant web services, including htsget services, to be aggregated into registries and made available via a standard API. The following considerations SHOULD be followed when registering htsget services within a service registry.

* Endpoints for different htsget data types should be registered as separate entities within the registry. If an htsget service provides both `reads` and `variants` data, both endpoints should be registered.
* The `url` property should reference the API's ticket endpoint for a single data type, excluding any particular `id` (i.e. an htsget reads API registration should provide the URL to the reads ticket endpoint, an htsget variants API registration should provide the URL to the variants ticket endpoint). Clients should be able to assume that:
   + Adding `/{id}` to the registered `url` will hit the corresponding ticket endpoint (i.e. `/reads/{id}` or `/variants/{id}`).
   + Adding `/service-info` to the registered `url` will hit the corresponding `service-info` endpoint (i.e. `/reads/service-info` or `/variants/service-info`).
* The value of the `type` object's `artifact` property should be `htsget` (i.e. the same as it appears in `service-info`)

Example listing of htsget reads API and variants API registrations from a service registry's `/services` endpoint:

```
[
   {
      "id": "net.exampleco.htsget-reads",
      "name": "ExampleCo htsget reads API",
      "description": "Serves alignment data (BAM, CRAM) via htsget protocol",
      "version": "0.1.0",
      "url": "https://htsget.exampleco.com/v1/reads",
      "organization":  {
         "name":       "ExampleCo",
         "url":        "https://exampleco.com"
      },
      "type": {
         "group": "org.ga4gh",
         "artifact": "htsget",
         "version": "1.2.1"
      }
   },
   {
      "id": "net.exampleco.htsget-variants",
      "name": "ExampleCo htsget variants API",
      "description": "Serves variant data (VCF, BCF) via htsget protocol",
      "version": "0.1.0",
      "url": "https://htsget.exampleco.com/v1/variants"
      "organization":  {
         "name":       "ExampleCo",
         "url":        "https://exampleco.com"
      },
      "type": {
         "group": "org.ga4gh",
         "artifact": "htsget",
         "version": "1.2.1"
      }
   }
]
```

# Possible future enhancements

* add a mechanism to request reads from more than one ID at a time (e.g. for a trio)
* allow clients to provide a suggested data block size to the server
* [dglazer] add a way to request reads in GA4GH binary format [^d] (e.g. fmt=proto)

## Existing clarification suggestions

[^a]: This should probably be specified as a (comma separated?) list in preference order.  If the client can accept both BAM and CRAM it is useful for it to indicate this and let the server pick whichever format it is most comfortable with.
[^d]: How will compression work in this case - can we benefit from columnar compression as does Parquet?


[CORS]:     http://www.w3.org/TR/cors/
[Data URI]: https://en.wikipedia.org/wiki/Data_URI_scheme
[ISO 8601]: http://www.iso.org/iso/iso8601
[RFC 2397]: https://www.ietf.org/rfc/rfc2397.txt
[RFC 2616]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html
[RFC 5246]: https://tools.ietf.org/html/rfc5246
[RFC 6749]: https://tools.ietf.org/html/rfc6749
[RFC 6750]: https://tools.ietf.org/html/rfc6750
[RFC 7231]: https://tools.ietf.org/html/rfc7231

<!-- vim:set linebreak: -->
