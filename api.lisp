(in-package #:cl-xml)

;;; Streaming helpers — walk the input and fire events directly on HANDLER.

(defun %stream-element (stream handler)
  "Parse an XML element whose opening '<' has already been consumed.
STREAM is positioned at the first character of the tag name.
Fires START-ELEMENT, any child events, and END-ELEMENT on HANDLER."
  (let* ((tag        (parse-name stream))
         (attributes (parse-attributes stream)))
    (skip-whitespace stream)
    (let ((ch (peek-char nil stream nil nil)))
      (cond
        ;; Self-closing tag: />
        ((eql ch #\/)
         (read-char stream)             ; consume '/'
         (unless (eql (read-char stream nil nil) #\>)
           (error "Expected '>' to close self-closing tag '~a'" tag))
         (start-element handler tag attributes)
         (end-element handler tag))
        ;; Opening tag: >  …content…  </tag>
        ((eql ch #\>)
         (read-char stream)             ; consume '>'
         (start-element handler tag attributes)
         (%stream-children stream tag handler)
         (end-element handler tag))
        (t
         (error "Expected '>' or '/>' after attributes of '~a'" tag))))))

(defun %stream-children (stream parent-tag handler)
  "Parse the content of an element, firing events on HANDLER, until the
matching closing tag is consumed."
  (loop
    (let ((ch (peek-char nil stream nil nil)))
      (unless ch
        (error "Unexpected end of input while parsing children of <~a>" parent-tag))
      (cond
        ;; Character data (possibly containing entity references)
        ((char/= ch #\<)
         (characters handler (parse-content-text stream)))
        ;; Markup starting with '<'
        (t
         (read-char stream)             ; consume '<'
         (let ((next (peek-char nil stream nil nil)))
           (unless next
             (error "Unexpected end of input after '<'"))
           (cond
             ;; Closing tag: </parent-tag>
             ((char= next #\/)
              (read-char stream)        ; consume '/'
              (let ((tag (parse-name stream)))
                (unless (string= tag parent-tag)
                  (error "Mismatched closing tag: expected </~a>, got </~a>"
                         parent-tag tag))
                (skip-whitespace stream)
                (unless (eql (read-char stream nil nil) #\>)
                  (error "Expected '>' to close </~a>" tag))
                (return)))
             ;; Nodes beginning with '<!'
             ((char= next #\!)
              (read-char stream)        ; consume '!'
              (let ((after-bang (peek-char nil stream nil nil)))
                (cond
                  ;; Comment: <!--
                  ((eql after-bang #\-)
                   (read-char stream)   ; consume first '-'
                   (unless (eql (peek-char nil stream nil nil) #\-)
                     (error "Expected second '-' in comment opening '<!--'"))
                   (read-char stream)   ; consume second '-'
                   (comment handler (xml-comment-data (parse-comment stream))))
                  ;; CDATA section: <![CDATA[
                  ((eql after-bang #\[)
                   (read-char stream)   ; consume '['
                   (loop for expected across "CDATA["
                         do (let ((c (read-char stream nil nil)))
                               (unless (and c (char= c expected))
                                 (error "Invalid CDATA section start"))))
                   (cdata-section handler (parse-cdata-section stream)))
                  (t
                   (error "Unexpected '<!' sequence")))))
             ;; Processing instruction: <?
             ((char= next #\?)
              (read-char stream)        ; consume '?'
              (let ((pi-node (parse-pi stream)))
                (processing-instruction handler
                                        (xml-pi-target pi-node)
                                        (xml-pi-data pi-node))))
             ;; Child element
             (t
              (%stream-element stream handler)))))))))

(defun %stream-prolog (stream handler)
  "Parse the XML document prolog, firing events on HANDLER for comments,
processing instructions, and DOCTYPE declarations.
Leaves STREAM positioned at the '<' of the root element."
  (loop
    (skip-whitespace stream)
    (unless (eql (peek-char nil stream nil nil) #\<)
      (return))
    (read-char stream)                  ; consume '<'
    (let ((next (peek-char nil stream nil nil)))
      (cond
        ;; Processing instruction or XML declaration: <?
        ((eql next #\?)
         (read-char stream)             ; consume '?'
         (let ((pi-node (parse-pi stream)))
           (processing-instruction handler
                                   (xml-pi-target pi-node)
                                   (xml-pi-data pi-node))))
        ;; Comment or DOCTYPE: <!
        ((eql next #\!)
         (read-char stream)             ; consume '!'
         (let ((after-bang (peek-char nil stream nil nil)))
           (cond
             ;; Comment: <!--
             ((eql after-bang #\-)
              (read-char stream)        ; consume first '-'
              (unless (eql (peek-char nil stream nil nil) #\-)
                (error "Expected second '-' in comment opening '<!--'"))
              (read-char stream)        ; consume second '-'
              (comment handler (xml-comment-data (parse-comment stream))))
             ;; DOCTYPE: <!DOCTYPE
             ((eql after-bang #\D)
              (loop for expected across "DOCTYPE"
                    do (let ((c (read-char stream nil nil)))
                         (unless (and c (char= c expected))
                           (error "Invalid DOCTYPE declaration"))))
              (doctype-declaration handler (parse-doctype stream)))
             (t
              (error "Unexpected '<!~c' in prolog" after-bang)))))
        ;; Anything else is the root element: unread '<' and stop
        (t
         (unread-char #\< stream)
         (return))))))

;;; Private SAX handler that collects all events into an adjustable vector.
;;; Used by PARSE-XML-EVENTS to produce the list of event structs.

(defclass %event-collector (sax-handler)
  ((%collector-events :initform (make-array 32 :adjustable t :fill-pointer 0)))
  (:documentation "Internal SAX handler that accumulates XML events into a list."))

(defmethod start-element ((h %event-collector) tag attributes)
  (vector-push-extend (make-xml-event-start-element :tag tag :attributes attributes)
                      (slot-value h '%collector-events)))

(defmethod end-element ((h %event-collector) tag)
  (vector-push-extend (make-xml-event-end-element :tag tag)
                      (slot-value h '%collector-events)))

(defmethod characters ((h %event-collector) text)
  (vector-push-extend (make-xml-event-characters :text text)
                      (slot-value h '%collector-events)))

(defmethod comment ((h %event-collector) data)
  (vector-push-extend (make-xml-event-comment :data data)
                      (slot-value h '%collector-events)))

(defmethod processing-instruction ((h %event-collector) target data)
  (vector-push-extend (make-xml-event-pi :target target :data data)
                      (slot-value h '%collector-events)))

(defmethod cdata-section ((h %event-collector) data)
  (vector-push-extend (make-xml-event-cdata :data data)
                      (slot-value h '%collector-events)))

(defmethod doctype-declaration ((h %event-collector) doctype)
  (vector-push-extend (make-xml-event-doctype :doctype doctype)
                      (slot-value h '%collector-events)))

(defmethod end-document ((h %event-collector))
  (coerce (slot-value h '%collector-events) 'list))

;;; Event-to-handler bridge

(defun reduce-events (events handler)
  "Replay a list of XML event structs produced by PARSE-XML-EVENTS onto HANDLER,
calling the appropriate SAX-HANDLER generic function for each event.
Returns no useful value; call END-DOCUMENT on the handler separately."
  (dolist (event events)
    (typecase event
      (xml-event-start-element
       (start-element handler
                      (xml-event-start-element-tag event)
                      (xml-event-start-element-attributes event)))
      (xml-event-end-element
       (end-element handler (xml-event-end-element-tag event)))
      (xml-event-characters
       (characters handler (xml-event-characters-text event)))
      (xml-event-comment
       (comment handler (xml-event-comment-data event)))
      (xml-event-pi
       (processing-instruction handler
                               (xml-event-pi-target event)
                               (xml-event-pi-data event)))
      (xml-event-cdata
       (cdata-section handler (xml-event-cdata-data event)))
      (xml-event-doctype
       (doctype-declaration handler (xml-event-doctype-doctype event))))))

;;; Public API

(defun parse-xml (input &key (handler (make-instance 'dom-builder)))
  "Parse INPUT (a string, standard character stream, or trivial-gray-streams
character stream) as an XML document using a SAX-style event handler.

When called without a HANDLER keyword argument, uses the built-in DOM-BUILDER
handler and returns an XML-DOCUMENT node (backward-compatible behaviour).

When a custom SAX-HANDLER subclass instance is supplied, the parser fires the
following generic functions on it as it walks the input:
  START-DOCUMENT, START-ELEMENT, END-ELEMENT, CHARACTERS, COMMENT,
  PROCESSING-INSTRUCTION, CDATA-SECTION, END-DOCUMENT.
The return value of END-DOCUMENT on the handler becomes the return value of
PARSE-XML.

Entity references (&amp; &lt; &gt; &quot; &apos; &#N; &#xN;) are expanded
before CHARACTERS and attribute values are reported."
  (let ((stream (%normalize-input input)))
    (start-document handler)
    (%stream-prolog stream handler)
    (unless (eql (peek-char nil stream nil nil) #\<)
      (error "Expected root element"))
    (read-char stream)                  ; consume '<'
    (%stream-element stream handler)
    (end-document handler)))

(defun parse-xml-events (input)
  "Parse INPUT (a string, standard character stream, or trivial-gray-streams
character stream) as an XML document and return a list of XML event structs
in document order.

The returned list contains zero or more of:
  xml-event-pi, xml-event-comment, xml-event-doctype  (from the prolog)
  xml-event-start-element, xml-event-end-element,
  xml-event-characters, xml-event-comment, xml-event-pi,
  xml-event-cdata                                      (from the document body)

Use PARSE-XML for the full streaming pipeline, or feed the returned list to
REDUCE-EVENTS with a custom SAX-HANDLER."
  (parse-xml input :handler (make-instance '%event-collector)))
