(in-package #:cl-xsd.test)

(def-suite cl-xsd-suite
  :description "Test suite for cl-xsd.")

(in-suite cl-xsd-suite)

;;; ── XSD: load-xsd — schema parsing ──────────────────────────────────────

(defparameter +simple-xsd+
  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"root\" type=\"xs:string\"/>
</xs:schema>"
  "A minimal XSD with a single xs:string element declaration.")

(test load-xsd-returns-schema
  "load-xsd returns an xsd-schema struct."
  (let ((schema (cl-xsd:load-xsd +simple-xsd+)))
    (is (cl-xsd:xsd-schema-p schema))))

(test load-xsd-parses-target-namespace
  "load-xsd captures the targetNamespace attribute."
  (let ((schema (cl-xsd:load-xsd
                 "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"
           targetNamespace=\"http://example.com/ns\">
  <xs:element name=\"root\" type=\"xs:string\"/>
</xs:schema>")))
    (is (string= "http://example.com/ns"
                 (cl-xsd:xsd-schema-target-namespace schema)))))

(test load-xsd-parses-top-level-element
  "load-xsd populates the elements alist with top-level xs:element declarations."
  (let* ((schema (cl-xsd:load-xsd +simple-xsd+))
         (elem   (cdr (assoc "root" (cl-xsd:xsd-schema-elements schema)
                             :test #'string=))))
    (is (not (null elem)))
    (is (cl-xsd:xsd-element-p elem))
    (is (string= "root" (cl-xsd:xsd-element-name elem)))
    (is (eq :string (cl-xsd:xsd-element-type elem)))
    (is (= 1 (cl-xsd:xsd-element-min-occurs elem)))
    (is (= 1 (cl-xsd:xsd-element-max-occurs elem)))))

(test load-xsd-parses-named-complex-type
  "load-xsd places a named xs:complexType in the types alist."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"person\" type=\"PersonType\"/>
  <xs:complexType name=\"PersonType\">
    <xs:sequence>
      <xs:element name=\"name\" type=\"xs:string\"/>
      <xs:element name=\"age\"  type=\"xs:integer\"/>
    </xs:sequence>
    <xs:attribute name=\"id\" type=\"xs:integer\" use=\"required\"/>
  </xs:complexType>
</xs:schema>"))
         (ctype (cdr (assoc "PersonType" (cl-xsd:xsd-schema-types schema)
                            :test #'string=))))
    (is (cl-xsd:xsd-complex-type-p ctype))
    (is (string= "PersonType" (cl-xsd:xsd-complex-type-name ctype)))
    (is (eq :sequence (cl-xsd:xsd-complex-type-compositor ctype)))
    (is (= 2 (length (cl-xsd:xsd-complex-type-elements ctype))))
    (is (= 1 (length (cl-xsd:xsd-complex-type-attributes ctype))))
    (is (eq :required
            (cl-xsd:xsd-attribute-use
             (first (cl-xsd:xsd-complex-type-attributes ctype)))))))

(test load-xsd-parses-named-simple-type
  "load-xsd places a named xs:simpleType with restriction in the types alist."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:simpleType name=\"SizeType\">
    <xs:restriction base=\"xs:string\">
      <xs:enumeration value=\"small\"/>
      <xs:enumeration value=\"medium\"/>
      <xs:enumeration value=\"large\"/>
    </xs:restriction>
  </xs:simpleType>
  <xs:element name=\"size\" type=\"SizeType\"/>
</xs:schema>"))
         (stype (cdr (assoc "SizeType" (cl-xsd:xsd-schema-types schema)
                            :test #'string=))))
    (is (cl-xsd:xsd-simple-type-p stype))
    (is (string= "SizeType" (cl-xsd:xsd-simple-type-name stype)))
    (is (eq :string (cl-xsd:xsd-simple-type-base stype)))
    (is (equal '("small" "medium" "large")
               (getf (cl-xsd:xsd-simple-type-facets stype) :enumeration)))))

(test load-xsd-parses-occurs
  "load-xsd parses minOccurs/maxOccurs including 'unbounded'."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"list\">
    <xs:complexType>
      <xs:sequence>
        <xs:element name=\"item\" type=\"xs:string\"
                    minOccurs=\"0\" maxOccurs=\"unbounded\"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (list-elem (cdr (assoc "list" (cl-xsd:xsd-schema-elements schema)
                                :test #'string=)))
         (ctype     (cl-xsd:xsd-element-type list-elem))
         (item-decl (first (cl-xsd:xsd-complex-type-elements ctype))))
    (is (= 0 (cl-xsd:xsd-element-min-occurs item-decl)))
    (is (eq :unbounded (cl-xsd:xsd-element-max-occurs item-decl)))))

(test load-xsd-inline-complex-type
  "load-xsd handles inline anonymous xs:complexType inside xs:element."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"root\">
    <xs:complexType>
      <xs:sequence>
        <xs:element name=\"child\" type=\"xs:integer\"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (root-elem (cdr (assoc "root" (cl-xsd:xsd-schema-elements schema)
                                :test #'string=)))
         (ctype     (cl-xsd:xsd-element-type root-elem)))
    (is (cl-xsd:xsd-complex-type-p ctype))
    (is (null (cl-xsd:xsd-complex-type-name ctype)))  ; anonymous
    (is (= 1 (length (cl-xsd:xsd-complex-type-elements ctype))))))

(test load-xsd-no-prefix
  "load-xsd accepts a schema document without a namespace prefix."
  (let ((schema (cl-xsd:load-xsd "<schema><element name=\"x\" type=\"string\"/></schema>")))
    (is (cl-xsd:xsd-schema-p schema))
    (is (= 1 (length (cl-xsd:xsd-schema-elements schema))))))

(test load-xsd-wrong-root-signals-error
  "load-xsd signals an error when the root element is not xs:schema."
  (signals error (cl-xsd:load-xsd "<root/>")))

;;; ── XSD: validate-xml — valid documents ──────────────────────────────────

(test validate-simple-string-element
  "validate-xml accepts a document whose root element holds a string value."
  (let ((schema (cl-xsd:load-xsd +simple-xsd+))
        (doc    (cl-xml:parse-xml "<root>hello</root>")))
    (is (cl-xsd:validate-xml doc schema))))

(test validate-complex-type-with-sequence
  "validate-xml accepts a document matching a complex type with xs:sequence."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"person\" type=\"PersonType\"/>
  <xs:complexType name=\"PersonType\">
    <xs:sequence>
      <xs:element name=\"name\" type=\"xs:string\"/>
      <xs:element name=\"age\"  type=\"xs:integer\"/>
    </xs:sequence>
    <xs:attribute name=\"id\" type=\"xs:integer\" use=\"required\"/>
  </xs:complexType>
</xs:schema>"))
         (doc (cl-xml:parse-xml
               "<person id=\"1\"><name>Alice</name><age>30</age></person>")))
    (is (cl-xsd:validate-xml doc schema))))

(test validate-optional-elements-absent
  "validate-xml accepts a document where optional children are absent."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"root\">
    <xs:complexType>
      <xs:sequence>
        <xs:element name=\"opt\" type=\"xs:string\" minOccurs=\"0\"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<root/>")))
    (is (cl-xsd:validate-xml doc schema))))

(test validate-unbounded-element
  "validate-xml accepts multiple occurrences of an unbounded element."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"list\">
    <xs:complexType>
      <xs:sequence>
        <xs:element name=\"item\" type=\"xs:string\"
                    minOccurs=\"0\" maxOccurs=\"unbounded\"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml
               "<list><item>a</item><item>b</item><item>c</item></list>")))
    (is (cl-xsd:validate-xml doc schema))))

(test validate-xs-all-compositor
  "validate-xml accepts xs:all children in any order."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"root\">
    <xs:complexType>
      <xs:all>
        <xs:element name=\"a\" type=\"xs:string\"/>
        <xs:element name=\"b\" type=\"xs:string\"/>
      </xs:all>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (doc-ab (cl-xml:parse-xml "<root><a>x</a><b>y</b></root>"))
         (doc-ba (cl-xml:parse-xml "<root><b>y</b><a>x</a></root>")))
    (is (cl-xsd:validate-xml doc-ab schema))
    (is (cl-xsd:validate-xml doc-ba schema))))

(test validate-xs-choice-compositor
  "validate-xml accepts either branch of an xs:choice."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"root\">
    <xs:complexType>
      <xs:choice>
        <xs:element name=\"a\" type=\"xs:string\"/>
        <xs:element name=\"b\" type=\"xs:integer\"/>
      </xs:choice>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (doc-a (cl-xml:parse-xml "<root><a>hello</a></root>"))
         (doc-b (cl-xml:parse-xml "<root><b>42</b></root>")))
    (is (cl-xsd:validate-xml doc-a schema))
    (is (cl-xsd:validate-xml doc-b schema))))

(test validate-enumeration-restriction
  "validate-xml accepts a value that is in an xs:enumeration list."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"size\">
    <xs:simpleType>
      <xs:restriction base=\"xs:string\">
        <xs:enumeration value=\"small\"/>
        <xs:enumeration value=\"medium\"/>
        <xs:enumeration value=\"large\"/>
      </xs:restriction>
    </xs:simpleType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<size>medium</size>")))
    (is (cl-xsd:validate-xml doc schema))))

(test validate-length-facet
  "validate-xml accepts a string whose length satisfies xs:minLength/xs:maxLength."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"code\">
    <xs:simpleType>
      <xs:restriction base=\"xs:string\">
        <xs:minLength value=\"2\"/>
        <xs:maxLength value=\"5\"/>
      </xs:restriction>
    </xs:simpleType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<code>abc</code>")))
    (is (cl-xsd:validate-xml doc schema))))

(test validate-min-inclusive-facet
  "validate-xml accepts a numeric value satisfying xs:minInclusive."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"score\">
    <xs:simpleType>
      <xs:restriction base=\"xs:integer\">
        <xs:minInclusive value=\"0\"/>
        <xs:maxInclusive value=\"100\"/>
      </xs:restriction>
    </xs:simpleType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<score>75</score>")))
    (is (cl-xsd:validate-xml doc schema))))

;;; ── XSD: validate-xml — invalid documents (error signaling) ─────────────

(test validate-wrong-root-element
  "validate-xml signals xsd-validation-error when the root element is undeclared."
  (let ((schema (cl-xsd:load-xsd +simple-xsd+))
        (doc    (cl-xml:parse-xml "<wrong>hello</wrong>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-wrong-type-integer
  "validate-xml signals xsd-validation-error for a non-integer value on xs:integer."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"count\" type=\"xs:integer\"/>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<count>not-a-number</count>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-wrong-type-boolean
  "validate-xml signals xsd-validation-error for an invalid xs:boolean value."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"flag\" type=\"xs:boolean\"/>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<flag>yes</flag>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-wrong-type-date
  "validate-xml signals xsd-validation-error for an invalid xs:date value."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"dob\" type=\"xs:date\"/>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<dob>01/01/2000</dob>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-missing-required-child
  "validate-xml signals xsd-validation-error when a required xs:sequence child is absent."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"person\">
    <xs:complexType>
      <xs:sequence>
        <xs:element name=\"name\" type=\"xs:string\"/>
        <xs:element name=\"age\"  type=\"xs:integer\"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<person><name>Alice</name></person>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-missing-required-attribute
  "validate-xml signals xsd-validation-error when a required attribute is absent."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"item\">
    <xs:complexType>
      <xs:attribute name=\"id\" type=\"xs:integer\" use=\"required\"/>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<item/>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-prohibited-attribute-present
  "validate-xml signals xsd-validation-error when a prohibited attribute appears."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"item\">
    <xs:complexType>
      <xs:attribute name=\"banned\" type=\"xs:string\" use=\"prohibited\"/>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<item banned=\"oops\"/>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-unexpected-element-in-sequence
  "validate-xml signals xsd-validation-error when an unexpected element appears."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"root\">
    <xs:complexType>
      <xs:sequence>
        <xs:element name=\"known\" type=\"xs:string\"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<root><known>ok</known><unknown/></root>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-enumeration-violation
  "validate-xml signals xsd-validation-error when a value is not in the enumeration."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"color\">
    <xs:simpleType>
      <xs:restriction base=\"xs:string\">
        <xs:enumeration value=\"red\"/>
        <xs:enumeration value=\"green\"/>
        <xs:enumeration value=\"blue\"/>
      </xs:restriction>
    </xs:simpleType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<color>purple</color>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-max-length-violation
  "validate-xml signals xsd-validation-error when a string exceeds xs:maxLength."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"pin\">
    <xs:simpleType>
      <xs:restriction base=\"xs:string\">
        <xs:maxLength value=\"4\"/>
      </xs:restriction>
    </xs:simpleType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<pin>12345</pin>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

(test validate-min-inclusive-violation
  "validate-xml signals xsd-validation-error when xs:minInclusive is violated."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"score\">
    <xs:simpleType>
      <xs:restriction base=\"xs:integer\">
        <xs:minInclusive value=\"0\"/>
        <xs:maxInclusive value=\"100\"/>
      </xs:restriction>
    </xs:simpleType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<score>-5</score>")))
    (signals cl-xsd:xsd-validation-error (cl-xsd:validate-xml doc schema))))

;;; ── XSD: xsd-validation-error condition ─────────────────────────────────

(test xsd-validation-error-has-message
  "xsd-validation-error condition carries a message string."
  (handler-case
      (cl-xsd:validate-xml (cl-xml:parse-xml "<wrong/>")
                           (cl-xsd:load-xsd +simple-xsd+))
    (cl-xsd:xsd-validation-error (e)
      (is (stringp (cl-xsd:xsd-validation-error-message e))))))

(test xsd-validation-error-path-is-set-for-nested-failure
  "xsd-validation-error carries a non-nil path for a failure inside a nested element."
  (let* ((schema (cl-xsd:load-xsd
                  "<?xml version=\"1.0\"?>
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
  <xs:element name=\"root\">
    <xs:complexType>
      <xs:sequence>
        <xs:element name=\"count\" type=\"xs:integer\"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>"))
         (doc (cl-xml:parse-xml "<root><count>bad</count></root>")))
    (handler-case (cl-xsd:validate-xml doc schema)
      (cl-xsd:xsd-validation-error (e)
        (is (not (null (cl-xsd:xsd-validation-error-path e))))))))

;;; ── XSD: built-in type validators ────────────────────────────────────────

(test builtin-integer-valid
  "xs:integer accepts digit strings and values with a leading sign."
  (let ((schema (cl-xsd:load-xsd
                 "<?xml version=\"1.0\"?><xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
<xs:element name=\"n\" type=\"xs:integer\"/></xs:schema>")))
    (is (cl-xsd:validate-xml (cl-xml:parse-xml "<n>0</n>") schema))
    (is (cl-xsd:validate-xml (cl-xml:parse-xml "<n>-42</n>") schema))
    (is (cl-xsd:validate-xml (cl-xml:parse-xml "<n>+999</n>") schema))))

(test builtin-boolean-valid-values
  "xs:boolean accepts true, false, 1, and 0."
  (let ((schema (cl-xsd:load-xsd
                 "<?xml version=\"1.0\"?><xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
<xs:element name=\"b\" type=\"xs:boolean\"/></xs:schema>")))
    (dolist (v '("true" "false" "1" "0"))
      (is (cl-xsd:validate-xml
           (cl-xml:parse-xml (format nil "<b>~a</b>" v)) schema)))))

(test builtin-decimal-valid
  "xs:decimal accepts decimal number strings."
  (let ((schema (cl-xsd:load-xsd
                 "<?xml version=\"1.0\"?><xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
<xs:element name=\"d\" type=\"xs:decimal\"/></xs:schema>")))
    (is (cl-xsd:validate-xml (cl-xml:parse-xml "<d>3.14</d>") schema))
    (is (cl-xsd:validate-xml (cl-xml:parse-xml "<d>-0.5</d>") schema))
    (is (cl-xsd:validate-xml (cl-xml:parse-xml "<d>42</d>") schema))))

(test builtin-date-valid
  "xs:date accepts YYYY-MM-DD formatted strings."
  (let ((schema (cl-xsd:load-xsd
                 "<?xml version=\"1.0\"?><xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
<xs:element name=\"dt\" type=\"xs:date\"/></xs:schema>")))
    (is (cl-xsd:validate-xml (cl-xml:parse-xml "<dt>2024-01-15</dt>") schema))))

(test builtin-positive-integer-rejects-zero
  "xs:positiveInteger rejects zero."
  (let ((schema (cl-xsd:load-xsd
                 "<?xml version=\"1.0\"?><xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
<xs:element name=\"n\" type=\"xs:positiveInteger\"/></xs:schema>")))
    (signals cl-xsd:xsd-validation-error
      (cl-xsd:validate-xml (cl-xml:parse-xml "<n>0</n>") schema))))

(test builtin-byte-range
  "xs:byte rejects a value outside [-128, 127]."
  (let ((schema (cl-xsd:load-xsd
                 "<?xml version=\"1.0\"?><xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">
<xs:element name=\"n\" type=\"xs:byte\"/></xs:schema>")))
    (is (cl-xsd:validate-xml (cl-xml:parse-xml "<n>127</n>") schema))
    (signals cl-xsd:xsd-validation-error
      (cl-xsd:validate-xml (cl-xml:parse-xml "<n>128</n>") schema))))

