# cl-xml

> **Note:** cl-xml is a temporary name as it is already taken on Quicklisp.

A Common Lisp XML reader, writer, and custom parser.

## Installation

```lisp
(ql:quickload "cl-xml")
```

## Parsing

`parse-xml` accepts a string and returns an `xml-document`.

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
- **§2.5 Comments** — `--` inside a comment body is an error
- **§2.7 CDATA sections** — content is literal (markup characters not interpreted)
- **§2.8 Prolog** — XML declaration and DOCTYPE handled; prolog comments/PIs preserved
- **§3.1 Attributes** — duplicate attribute names are an error
- **§4.6 References** — `&amp;` `&lt;` `&gt;` `&quot;` `&apos;` `&#N;` `&#xN;` expanded

## License

MIT
