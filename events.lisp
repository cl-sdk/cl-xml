(in-package #:cl-xml)

;;; XML event types — the intermediate representation between the tokeniser
;;; and any downstream processor (SAX handler, validator, etc.).

(defstruct xml-event-start-element
  "Event fired when an opening (or self-closing) tag is encountered.
TAG is a string; ATTRIBUTES is an alist of (name . value) string pairs."
  tag
  attributes)

(defstruct xml-event-end-element
  "Event fired when a closing (or self-closing) tag has been fully processed.
TAG is a string."
  tag)

(defstruct xml-event-characters
  "Event fired for a run of character data content.
TEXT is a string with entity and character references already expanded."
  text)

(defstruct xml-event-comment
  "Event fired when a comment is encountered.
DATA is the raw comment body (between <!-- and -->)."
  data)

(defstruct xml-event-pi
  "Event fired when a processing instruction is encountered.
TARGET and DATA are both strings."
  target
  data)

(defstruct xml-event-cdata
  "Event fired when a CDATA section is encountered.
DATA is the raw content string (between <![CDATA[ and ]]>)."
  data)

(defstruct xml-event-doctype
  "Event fired when a DOCTYPE declaration is parsed.
DOCTYPE is an xml-doctype struct."
  doctype)

;;; Stream normalisation helper

(defun %normalize-input (input)
  "Coerce INPUT (string, standard stream, or Gray stream) to a character
input stream suitable for the tokeniser."
  (etypecase input
    (string (make-string-input-stream input))
    (fundamental-character-input-stream input)
    (stream input)))
