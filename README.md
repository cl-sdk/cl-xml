# cl-xml

> **Note:** cl-xml is a temporary name as it is already taken on Quicklisp.

A Common Lisp XML reader, writer, and custom parser.

## Installation

```lisp
(ql:quickload "cl-xml")
```

## Parsing

`parse-xml` accepts a string and an optional `:handler` keyword argument.

* **Default behaviour** — when no handler is given, `parse-xml` returns an
  `xml-document` built by the built-in `dom-builder` handler (fully
  backward-compatible).
* **SAX behaviour** — when a custom handler is supplied, the parser fires
  events on it and returns whatever `end-document` returns.

```lisp
(defvar *doc*
  (cl-xml:parse-xml "<?xml version=\"1.0\"?>
<!-- preamble -->
<root>
  <item id=\"1\">hello &amp; world</item>
  <!-- note -->
  <![CDATA[literal <text>]]>
  <?app instruction?>
</root>"))
```

### SAX parsing

Provide a subclass of `sax-handler` and pass an instance as `:handler` to
`parse-xml`.  Specialize only the event methods you care about; unspecialized
methods are no-ops.

```lisp
(defclass my-handler (cl-xml:sax-handler) ())

(defmethod cl-xml:start-element ((h my-handler) tag attributes)
  (format t "open  ~a ~a~%" tag attributes))

(defmethod cl-xml:end-element ((h my-handler) tag)
  (format t "close ~a~%" tag))

(defmethod cl-xml:end-document ((h my-handler))
  :done)

(cl-xml:parse-xml "<root><child /></root>" :handler (make-instance 'my-handler))
;; open  root nil
;; open  child nil
;; close child
;; close root
;; => :done
```

#### SAX handler generic functions

| Generic function | When called |
|---|---|
| `(start-document handler)` | once, before any other event |
| `(end-document handler)` | once, after all events; return value is `parse-xml`'s result |
| `(start-element handler tag attributes)` | opening / self-closing tag |
| `(end-element handler tag)` | closing / self-closing tag |
| `(characters handler text)` | character data (entity refs already expanded) |
| `(comment handler data)` | `<!-- … -->` comment |
| `(processing-instruction handler target data)` | `<?target data?>` PI |
| `(cdata-section handler data)` | `<![CDATA[…]]>` section |
```

### xml-document

The top-level result of `parse-xml`.

| Accessor | Returns |
|---|---|
| `xml-document-prolog` | list of `xml-comment` / `xml-pi` nodes before the root element |
| `xml-document-root`   | the root `xml-node` |

```lisp
(cl-xml:xml-document-prolog *doc*)
;; => (#<xml-pi "xml" …> #<xml-comment " preamble ">)

(cl-xml:xml-node-tag (cl-xml:xml-document-root *doc*))
;; => "root"
```

### xml-node (element)

| Accessor | Returns |
|---|---|
| `xml-node-tag`        | element name as a string |
| `xml-node-attributes` | alist of `(name . value)` string pairs |
| `xml-node-children`   | list of child nodes (see node types below) |

```lisp
(let* ((root (cl-xml:xml-document-root *doc*))
       (item (first (cl-xml:xml-node-children root))))
  (cl-xml:xml-node-tag item)                      ; => "item"
  (cl-xml:xml-node-attributes item)               ; => (("id" . "1"))
  (cl-xml:xml-node-children item))                ; => ("hello & world")
```

### xml-comment

Represents a `<!-- … -->` comment.

| Accessor | Returns |
|---|---|
| `xml-comment-data` | comment body as a string |

### xml-pi (processing instruction)

Represents a `<?target data?>` processing instruction.

| Accessor | Returns |
|---|---|
| `xml-pi-target` | target name as a string |
| `xml-pi-data`   | data string (may be empty) |

### xml-cdata

Represents a `<![CDATA[…]]>` section.

| Accessor | Returns |
|---|---|
| `xml-cdata-data` | literal content as a string |

### Node types inside xml-node-children

Each child of an `xml-node` is one of:

| Type | Produced by |
|---|---|
| `xml-node`    | `<child …>` / `<child />` |
| `xml-comment` | `<!-- … -->` |
| `xml-pi`      | `<?target data?>` |
| `xml-cdata`   | `<![CDATA[…]]>` |
| `string`      | character data / entity references |

Whitespace-only character data between elements is discarded.

## XML 1.0 conformance

- **§2.3 Names** — `NameStartChar` / `NameChar` Unicode ranges enforced
- **§2.3 / §3.3.3 Attribute values** — bare `<` is an error; entity/character references expanded
- **§2.4 CharData** — the sequence `]]>` in character data is a well-formedness error
- **§2.5 Comments** — `--` inside a comment body is an error
- **§2.6 Processing instructions** — PI targets matching `[xX][mM][lL]` are reserved and rejected
- **§2.7 CDATA sections** — content is literal (markup characters not interpreted)
- **§2.8 Prolog / Epilog** — XML declaration and DOCTYPE handled; content after the root element (other than whitespace, comments, and PIs) is rejected
- **§3.1 Attributes** — duplicate attribute names are an error
- **§4.1 Character references** — code points outside the XML 1.0 Char production are rejected
- **§4.6 References** — `&amp;` `&lt;` `&gt;` `&quot;` `&apos;` `&#N;` `&#xN;` expanded
- **§2.11 End-of-line handling** — CR, CR+LF normalized to LF (string input)

### W3C XML Conformance Test Suite

To run the W3C XML Conformance Test Suites
([xmlts20130923.zip](https://www.w3.org/XML/Test/xmlts20130923.zip)):

```sh
# Download, extract, and run (requires network access to www.w3.org):
./run-conformance-tests.sh

# Or point to an already-extracted tree:
XMLTS_DIR=/path/to/xmlconf ./run-conformance-tests.sh
```

The conformance runner is also available as a standalone ASDF system:

```lisp
(asdf:load-system :cl-xml.conformance)

;; Run and print a report
(cl-xml.conformance:run-conformance-tests)

;; Point to a specific xmlconf/ directory
(cl-xml.conformance:run-conformance-tests
  :dir #p"/path/to/xmlconf/")
```

**Known limitations** (tests that may not pass):

- *External entities / DTD processing* — cl-xml does not resolve external
  entities or process DTD declarations, so `TYPE="valid"` tests with
  `ENTITIES` other than `"none"` are skipped.
- *Character encoding* — only UTF-8 and ASCII input is fully supported;
  test files in other encodings are attempted as UTF-8.
- *XML declaration placement* — the XML declaration is parsed as a
  processing instruction; a misplaced `<?xml...?>` later in the prolog
  will be accepted rather than rejected.

## License

MIT
